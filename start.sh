#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Skip admin build - admin is disabled for now
echo "Building backend only (admin disabled)..."
NODE_OPTIONS='--max-old-space-size=1536' medusa build

# Start server
echo "Starting Medusa API server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}