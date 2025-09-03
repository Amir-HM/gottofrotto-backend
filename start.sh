#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Build application with admin UI
echo "Building application (backend + admin UI)..."
NODE_OPTIONS='--max-old-space-size=1536' medusa build

# Debug the exact error by examining what Medusa is looking for
echo "Debugging Medusa admin configuration..."
echo "Current working directory:"
pwd
echo "Full .medusa structure:"
find .medusa -name "*.html" -o -name "admin" -type d 2>/dev/null
echo "Files in current directory:"
ls -la | grep -E "(medusa|admin)" || echo "No medusa/admin files in root"

# Let's create the admin files EXACTLY where Medusa expects them
if [ -f ".medusa/server/public/admin/index.html" ]; then
    echo "✅ Admin files found, setting up all possible locations..."
    
    # Try putting them directly in the project root under admin/
    mkdir -p admin
    cp -r .medusa/server/public/admin/* admin/ 2>/dev/null || true
    echo "Admin files copied to ./admin/"
    
    # Also try .medusa/admin
    mkdir -p .medusa/admin  
    cp -r .medusa/server/public/admin/* .medusa/admin/ 2>/dev/null || true
    echo "Admin files copied to .medusa/admin/"
    
    # And .medusa/client/admin
    mkdir -p .medusa/client/admin
    cp -r .medusa/server/public/admin/* .medusa/client/admin/ 2>/dev/null || true  
    echo "Admin files copied to .medusa/client/admin/"
    
    # List all admin index.html files we've created
    echo "All admin index.html locations:"
    find . -name "index.html" -path "*admin*" 2>/dev/null || echo "None found"
else
    echo "❌ No admin files found after build"
fi

# Start server (migrations already completed)
echo "Starting Medusa API server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}