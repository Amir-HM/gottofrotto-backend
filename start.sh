#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Build application with admin UI
echo "Building application (backend + admin UI)..."
NODE_OPTIONS='--max-old-space-size=1536' medusa build

# Verify admin build files exist and ensure they're in the right place
echo "Verifying admin build..."
echo "Checking all possible admin locations:"
find . -name "index.html" -path "*/admin/*" 2>/dev/null || echo "No admin index.html found"

# Copy admin files to the location Medusa expects
if [ -f ".medusa/server/public/admin/index.html" ]; then
    echo "✅ Admin files found in build location"
    echo "Creating additional symlinks/copies for Medusa compatibility..."
    
    # Create client admin directory if it doesn't exist
    mkdir -p .medusa/client/admin
    
    # Copy admin files to client location as well (some versions expect it here)
    if [ ! -f ".medusa/client/admin/index.html" ]; then
        cp -r .medusa/server/public/admin/* .medusa/client/admin/ 2>/dev/null || true
        echo "Admin files copied to .medusa/client/admin/"
    fi
    
    # Also try creating in root .medusa/admin
    mkdir -p .medusa/admin
    if [ ! -f ".medusa/admin/index.html" ]; then
        cp -r .medusa/server/public/admin/* .medusa/admin/ 2>/dev/null || true
        echo "Admin files copied to .medusa/admin/"
    fi
else
    echo "❌ Admin files not found in expected location"
fi

# Start server (migrations already completed)
echo "Starting Medusa API server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}