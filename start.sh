#!/bin/bash
set -e

echo "Starting Medusa server with admin dashboard..."

# Set environment variables for production
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment:"
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"

# Skip build - admin is disabled in production
echo "Admin disabled in production for stability"

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server
echo "Starting server..."
medusa start --host 0.0.0.0 --port ${PORT:-9000}