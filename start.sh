#!/bin/bash
set -e

echo "Starting Medusa server on Digital Ocean..."

# Set environment variables for runtime
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment configured:"
echo "HOST: 0.0.0.0"
echo "PORT: $PORT"
echo "NODE_ENV: $NODE_ENV"

# Check database connection and create if needed
echo "Testing database connection..."
npx medusa db:create || echo "Database already exists or connection failed"

# Always build since files don't persist from build phase to runtime
echo "Building admin dashboard..."
export NODE_OPTIONS='--max-old-space-size=768'
npx medusa build

echo "Verifying build output..."
ls -la .medusa/server/public/admin/ || echo "Admin directory not found after build"

# Run database migrations with more verbose output
echo "Running database migrations..."
npx medusa db:migrate

# Seed the database if it's empty (for new Digital Ocean database)
echo "Checking if database needs seeding..."
npx medusa exec --file ./src/scripts/seed.ts || echo "Seeding failed or database already seeded"

# Start the server with explicit host and port
echo "Starting server on 0.0.0.0:${PORT:-9000}..."
npx medusa start --host 0.0.0.0 --port ${PORT:-9000}