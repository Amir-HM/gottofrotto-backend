#!/bin/bash
set -e

echo "Starting Medusa server with admin dashboard..."

# Set environment variables for production
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment:"
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"

# Build admin dashboard - try with reduced resources
echo "Building admin dashboard..."
NODE_OPTIONS='--max-old-space-size=768' medusa build || {
    echo "Build failed, starting without admin..."
    export DISABLE_ADMIN=true
}

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server
echo "Starting server..."
medusa start --host 0.0.0.0 --port ${PORT:-9000}