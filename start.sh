#!/bin/bash
set -e

echo "Starting Medusa deployment process..."

# Set environment variables
export HOST=0.0.0.0
export NODE_TLS_REJECT_UNAUTHORIZED=0
export NODE_OPTIONS='--max-old-space-size=1024'

echo "Environment configured:"
echo "HOST: $HOST"
echo "PORT: $PORT"
echo "NODE_ENV: $NODE_ENV"

# Build the application
echo "Building application..."
npx medusa build

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server
echo "Starting Medusa server..."
npx medusa start --host 0.0.0.0