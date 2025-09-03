#!/bin/bash
set -e

echo "Starting Medusa server on Digital Ocean..."

# Set environment variables for runtime
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment configured:"
echo "HOST: 0.0.0.0"
echo "PORT: $PORT"
echo "NODE_ENV: $NODE_ENV"
echo "DATABASE_URL: ${DATABASE_URL:0:50}..." # Only show first 50 chars for security

# Create .env file for Medusa CLI commands since they require it
echo "Creating .env file for Medusa CLI..."
cat > .env << EOF
DATABASE_URL=$DATABASE_URL
JWT_SECRET=$JWT_SECRET
COOKIE_SECRET=$COOKIE_SECRET
NODE_ENV=$NODE_ENV
STORE_CORS=$STORE_CORS
ADMIN_CORS=$ADMIN_CORS
AUTH_CORS=$AUTH_CORS
EOF

echo "Skipping database creation - Digital Ocean database already exists"

# Run database migrations BEFORE building to ensure tables exist
echo "Running database migrations FIRST..."
echo "Attempting to create database tables..."

# Try migration using npx (yarn dlx not available in yarn 1.x)
echo "Starting migration process..."
if npx @medusajs/cli@latest db:migrate; then
    echo "Migration completed successfully!"
else
    MIGRATION_EXIT_CODE=$?
    echo "Migration failed with exit code: $MIGRATION_EXIT_CODE"
    echo "Retrying migration once more..."
    if npx @medusajs/cli@latest db:migrate; then
        echo "Migration completed successfully on retry!"
    else
        echo "ERROR: All migration attempts failed!"
        echo "Database URL: ${DATABASE_URL:0:50}..."
        echo "Checking .env file contents:"
        head -3 .env || echo "No .env file found"
        exit 1
    fi
fi

# Seed the database if it's empty (for new Digital Ocean database)
echo "Checking if database needs seeding..."
if ! yarn seed; then
    echo "Warning: Seeding failed or database already seeded"
fi

# Always build since files don't persist from build phase to runtime
echo "Building admin dashboard..."
export NODE_OPTIONS='--max-old-space-size=768'
yarn build

echo "Build completed - checking files..."
echo "Verifying build output..."
ls -la .medusa/server/public/admin/ || echo "Admin directory not found after build"

# Start the server with explicit host and port
echo "Starting server on 0.0.0.0:${PORT:-9000}..."
# Start server in background
npx @medusajs/cli@latest start --host 0.0.0.0 --port ${PORT:-9000} &
SERVER_PID=$!

echo "Server started with PID $SERVER_PID, waiting for it to accept connections..."

# Wait for server to be ready (poll localhost:PORT)
PORT_TO_CHECK=${PORT:-9000}
MAX_WAIT=60
WAITED=0
while ! nc -z 127.0.0.1 "$PORT_TO_CHECK"; do
  sleep 1
  WAITED=$((WAITED+1))
  if [ "$WAITED" -ge "$MAX_WAIT" ]; then
    echo "Server did not start within $MAX_WAIT seconds"
    kill $SERVER_PID || true
    exit 1
  fi
done

echo "Server is accepting connections on port $PORT_TO_CHECK"

# Run seeding in background so startup is not blocked by seeding
echo "Starting seeding in background..."
(yarn seed && echo "Seeding completed") &
SEED_PID=$!

echo "Seeding started with PID $SEED_PID"

# Wait on the server process so container stays alive
wait $SERVER_PID
EXIT_CODE=$?

echo "Server process exited with code $EXIT_CODE"
exit $EXIT_CODE