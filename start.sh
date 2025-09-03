#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Build application with admin UI
echo "Building application (backend + admin UI)..."
NODE_OPTIONS='--max-old-space-size=1536' medusa build

# Verify admin build files exist
echo "Verifying admin build..."
echo "Checking all possible admin locations:"
find . -name "index.html" -path "*/admin/*" 2>/dev/null || echo "No admin index.html found"
echo "Contents of .medusa directory:"
find .medusa -type f 2>/dev/null | head -20

# Start server (migrations already completed)
echo "Starting Medusa API server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}