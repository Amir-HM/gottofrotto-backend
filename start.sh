#!/bin/bash
set -e

echo "Starting Medusa production server..."

# Set environment variables for production
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment:"
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server
echo "Starting server..."
medusa start --host 0.0.0.0 --port ${PORT:-9000}