#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Build application with admin UI
echo "Building application (backend + admin UI)..."
NODE_OPTIONS='--max-old-space-size=1536' medusa build

# Run database migrations
echo "Running database migrations..."
medusa db:migrate

# Start server
echo "Starting Medusa API server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}