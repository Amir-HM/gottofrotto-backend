#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Skip build - use pre-built files from buildpack
echo "Using pre-built admin files from buildpack..."

# Skip migrations - already done
echo "Skipping migrations..."

# Start server with minimal approach
echo "Starting Medusa server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}