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

# Ensure the process binds to all interfaces so Digital Ocean health checks
# that hit the pod IP (not just localhost) succeed.
export HOST=${HOST:-0.0.0.0}
export PORT=${PORT:-9000}

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

# Migrations completed. We'll run seeding after the server is accepting
# connections (in background) to avoid blocking readiness probes.

# Always build since files don't persist from build phase to runtime
echo "Building admin dashboard..."
export NODE_OPTIONS='--max-old-space-size=768'
yarn build

echo "Build completed - checking files..."
echo "Verifying build output..."
ls -la .medusa/server/public/admin/ || echo "Admin directory not found after build"

# Start the server with explicit host and port
echo "Starting server on ${HOST}:${PORT}..."
# Start server in background (still pass host/port explicitly)
npx @medusajs/cli@latest start --host ${HOST} --port ${PORT} &
SERVER_PID=$!

echo "Server started with PID $SERVER_PID, waiting for it to accept connections..."

# Wait for server to be ready (poll localhost:PORT)
PORT_TO_CHECK=${PORT:-9000}
# Give the server more time to bind in noisy environments
MAX_WAIT=120
WAITED=0

# Get a container-local IP to check (if available)
CONTAINER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo "Waiting up to $MAX_WAIT seconds for server to accept connections on port $PORT_TO_CHECK..."
while true; do
  # Check localhost first
  if bash -c "</dev/tcp/127.0.0.1/$PORT_TO_CHECK" >/dev/null 2>&1; then
    echo "Server is accepting connections on 127.0.0.1:$PORT_TO_CHECK"
    break
  fi

  # If we have a container IP, try that too (Digital Ocean health checks target the pod IP)
  if [ -n "$CONTAINER_IP" ]; then
    if bash -c "</dev/tcp/$CONTAINER_IP/$PORT_TO_CHECK" >/dev/null 2>&1; then
      echo "Server is accepting connections on $CONTAINER_IP:$PORT_TO_CHECK"
      break
    fi
  fi

  sleep 1
  WAITED=$((WAITED+1))
  if [ "$WAITED" -ge "$MAX_WAIT" ]; then
    echo "Server did not start within $MAX_WAIT seconds"
    kill $SERVER_PID || true
    exit 1
  fi
done

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