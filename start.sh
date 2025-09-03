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

# Test database connection with detailed error handling
echo "Testing database connection..."
# Skip db:create since Digital Ocean database already exists
# if ! npx medusa db:create; then
#     echo "Warning: Database creation failed or database already exists"
# fi
echo "Skipping database creation - Digital Ocean database already exists"

# Run database migrations BEFORE building to ensure tables exist
echo "Running database migrations FIRST..."
echo "Attempting to create database tables..."

# Try migration without timeout first
echo "Starting migration process..."
if npx medusa db:migrate; then
    echo "Migration completed successfully!"
else
    MIGRATION_EXIT_CODE=$?
    echo "Migration failed with exit code: $MIGRATION_EXIT_CODE"
    echo "Retrying migration once more..."
    if npx medusa db:migrate; then
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
if ! npx medusa exec --file ./src/scripts/seed.ts; then
    echo "Warning: Seeding failed or database already seeded"
fi

# Always build since files don't persist from build phase to runtime
echo "Building admin dashboard..."
export NODE_OPTIONS='--max-old-space-size=768'
npx medusa build

echo "Build completed - checking files..."
echo "Verifying build output..."
ls -la .medusa/server/public/admin/ || echo "Admin directory not found after build"

# Always build since files don't persist from build phase to runtime
echo "Building admin dashboard..."
export NODE_OPTIONS='--max-old-space-size=768'
npx medusa build

echo "Build completed - checking files..."
echo "Verifying build output..."
ls -la .medusa/server/public/admin/ || echo "Admin directory not found after build"

echo "About to start database migration process..."

# Run database migrations with detailed error handling
echo "Running database migrations..."
echo "Attempting to create database tables..."

# Try migration without timeout first
echo "Starting migration process..."
if npx medusa db:migrate; then
    echo "Migration completed successfully!"
else
    MIGRATION_EXIT_CODE=$?
    echo "Migration failed with exit code: $MIGRATION_EXIT_CODE"
    echo "Retrying migration once more..."
    if npx medusa db:migrate; then
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
if ! npx medusa exec --file ./src/scripts/seed.ts; then
    echo "Warning: Seeding failed or database already seeded"
fi

# Start the server with explicit host and port
echo "Starting server on 0.0.0.0:${PORT:-9000}..."
npx medusa start --host 0.0.0.0 --port ${PORT:-9000}