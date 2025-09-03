#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Build with reduced memory for resource-constrained environments
echo "Building application (backend + admin UI)..."
echo "Using reduced memory allocation for build..."
NODE_OPTIONS='--max-old-space-size=512' medusa build

# Run database migrations
echo "Running database migrations..."
medusa db:migrate

# Start server with reduced memory
echo "Starting Medusa API server..."
NODE_OPTIONS='--max-old-space-size=256' exec medusa start --host 0.0.0.0 --port ${PORT:-9000}