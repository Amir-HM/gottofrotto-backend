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

# Start the server using the built files directly
echo "About to start medusa server using built files..."
echo "Checking server build directory structure..."
ls -la .medusa/server/
echo "Contents of server directory:"
find .medusa/server/ -name "*.js" | head -10
echo "Looking for main server file..."
if [ -f ".medusa/server/index.js" ]; then
    echo "Found index.js, starting server..."
    cd .medusa/server && HOST=0.0.0.0 PORT=${PORT:-9000} NODE_ENV=production node index.js
elif [ -f ".medusa/server/server.js" ]; then
    echo "Found server.js, starting server..."
    cd .medusa/server && HOST=0.0.0.0 PORT=${PORT:-9000} NODE_ENV=production node server.js
else
    echo "Looking for any js files to start..."
    cd .medusa/server && find . -name "*.js" -maxdepth 2
    echo "Trying to start with the first .js file found..."
    JS_FILE=$(find . -name "*.js" -maxdepth 2 | head -1)
    if [ -n "$JS_FILE" ]; then
        echo "Starting with: $JS_FILE"
        HOST=0.0.0.0 PORT=${PORT:-9000} NODE_ENV=production node "$JS_FILE"
    else
        echo "ERROR: No JavaScript files found to start server!"
        exit 1
    fi
fi