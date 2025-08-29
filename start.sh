#!/bin/bash
set -e

echo "Starting Medusa production server..."

# Set environment variables for production
export NODE_TLS_REJECT_UNAUTHORIZED=0
export NODE_OPTIONS='--max-old-space-size=1024'

echo "Environment:"
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"

# Build admin dashboard (required since build artifacts don't persist)
echo "Building admin dashboard..."
medusa build

echo "Verifying build output..."
ls -la .medusa/server/public/admin/ || echo "Admin directory not found"

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server
echo "Starting server..."
medusa start --host 0.0.0.0 --port ${PORT:-9000}