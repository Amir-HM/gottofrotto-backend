#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Build admin at startup since buildpack build files aren't persisting
echo "Building admin dashboard for production..."
NODE_OPTIONS='--max-old-space-size=1536' medusa build

# Verify admin files exist
echo "Verifying admin build files..."
if [ -f ".medusa/server/public/admin/index.html" ]; then
    echo "✓ Admin files found"
else
    echo "✗ Admin files missing!"
    exit 1
fi

# Start server
echo "Starting Medusa server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}