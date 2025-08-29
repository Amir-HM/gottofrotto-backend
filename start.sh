#!/bin/bash
set -e

echo "Starting Medusa API server (admin disabled for production)..."

# Set environment variables for production
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment:"
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server (admin is disabled in config)
echo "Starting API server..."
medusa start --host 0.0.0.0 --port ${PORT:-9000}