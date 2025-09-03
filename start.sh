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
if [ -d ".medusa/server/public/admin" ]; then
    echo "Admin build directory found"
    ls -la .medusa/server/public/admin/
    if [ -f ".medusa/server/public/admin/index.html" ]; then
        echo "✅ Admin index.html found"
    else
        echo "❌ Admin index.html missing"
    fi
else
    echo "❌ Admin build directory missing"
fi

# Start server (migrations already completed)
echo "Starting Medusa API server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}