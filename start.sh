#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Build admin at startup since buildpack build files aren't persisting
echo "Building admin dashboard for production..."
NODE_OPTIONS='--max-old-space-size=1536' medusa build

# Verify admin files exist and debug paths
echo "Verifying admin build files..."
echo "Current directory: $(pwd)"
echo "Looking for admin files in multiple locations:"
find . -name "index.html" -type f 2>/dev/null | grep -E "(admin|medusa)" || echo "No admin index.html found"
echo "Directory structure of .medusa:"
ls -la .medusa/ 2>/dev/null || echo "No .medusa directory"
echo "Directory structure of .medusa/server/public:"
ls -la .medusa/server/public/ 2>/dev/null || echo "No public directory"
echo "Directory structure of .medusa/server/public/admin:"
ls -la .medusa/server/public/admin/ 2>/dev/null || echo "No admin directory"

if [ -f ".medusa/server/public/admin/index.html" ]; then
    echo "✓ Admin files found at expected location"
else
    echo "✗ Admin files missing from expected location!"
    echo "Searching entire filesystem for admin build files..."
    find /workspace -name "index.html" -path "*/admin/*" 2>/dev/null || echo "No admin index.html found anywhere"
fi

# Start server
echo "Starting Medusa server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}