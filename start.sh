#!/bin/bash
set -e

echo "Starting Medusa production server..."

# Set environment variables for production
export NODE_TLS_REJECT_UNAUTHORIZED=0
export NODE_OPTIONS='--max-old-space-size=1024'

echo "Environment:"
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"

# Build backend first (faster, essential for API)
echo "Building backend..."
NODE_OPTIONS='--max-old-space-size=256' medusa build --admin-only || echo "Admin build failed, API will still work"

echo "Build completed, checking output..."
ls -la .medusa/ 2>/dev/null || echo "No .medusa directory found"

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server
echo "Starting server..."
medusa start --host 0.0.0.0 --port ${PORT:-9000}