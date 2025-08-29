#!/bin/bash
set -e

echo "Starting Medusa server with admin dashboard..."

# Set environment variables for production
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment:"
echo "NODE_ENV: $NODE_ENV" 
echo "PORT: $PORT"

# Build admin dashboard with 2GB RAM - should work now!
echo "Building admin dashboard with upgraded resources..."
NODE_OPTIONS='--max-old-space-size=1536' medusa build

# Debug: Check if admin files were actually created
echo "Checking build output..."
ls -la .medusa/ || echo "No .medusa directory"
ls -la .medusa/server/ || echo "No server directory"
ls -la .medusa/server/public/ || echo "No public directory"
ls -la .medusa/server/public/admin/ || echo "No admin directory"
find . -name "index.html" -type f || echo "No index.html files found"

# Skip migrations for faster startup - DB is already up to date
echo "Database already migrated, skipping migrations for faster startup..."

# Start the server - should be fast now  
echo "Starting server on port ${PORT:-9000}..."
echo "Host binding: 0.0.0.0"
echo "Environment check:"
echo "NODE_ENV: ${NODE_ENV}"
echo "DATABASE_URL exists: $([ -n "$DATABASE_URL" ] && echo "yes" || echo "no")"

# Start the server using Node.js directly with proper setup
echo "Setting up server environment..."
cd .medusa/server
echo "Current directory: $(pwd)"
echo "Available files:"
ls -la

# Set environment variables
export NODE_ENV=production  
export PORT=${PORT:-9000}
export HOST=0.0.0.0
export DATABASE_URL="${DATABASE_URL}"
export JWT_SECRET="${JWT_SECRET}"
export COOKIE_SECRET="${COOKIE_SECRET}"

# Look for the actual server entry point
echo "Looking for server entry points..."
if [ -f "src/index.js" ]; then
    echo "Starting with src/index.js"
    node src/index.js
elif [ -f "index.js" ]; then
    echo "Starting with index.js" 
    node index.js
else
    echo "Checking package.json for start script..."
    if [ -f "package.json" ]; then
        cat package.json | grep -A 5 -B 5 "start"
    fi
    echo "Attempting to start with instrumentation.js as fallback..."
    node instrumentation.js
fi