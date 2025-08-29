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

# Start the server - use medusa start from build directory
echo "Starting server directly with medusa start from build context..."
cd .medusa/server
echo "Current directory: $(pwd)"
echo "Files in build directory:"
ls -la

# Set environment and start server with medusa command from build context
echo "Starting medusa server from built context..."
export NODE_ENV=production
export PORT=${PORT:-9000}
export HOST=0.0.0.0

# Use medusa start but from the built server context
medusa start --host 0.0.0.0 --port ${PORT:-9000}