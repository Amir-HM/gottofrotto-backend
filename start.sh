#!/bin/bash
set -e

echo "Starting Medusa server..."

# Set environment variables for runtime
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment configured:"
echo "HOST: 0.0.0.0"
echo "PORT: $PORT"
echo "NODE_ENV: $NODE_ENV"

# Always build since files don't persist from build phase to runtime
echo "Building admin dashboard..."
export NODE_OPTIONS='--max-old-space-size=768'
npx medusa build

echo "Verifying build output..."
ls -la .medusa/server/public/admin/ || echo "Admin directory not found after build"

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server with explicit host and port
echo "Starting server on 0.0.0.0:${PORT:-9000}..."
npx medusa start --host 0.0.0.0 --port ${PORT:-9000}