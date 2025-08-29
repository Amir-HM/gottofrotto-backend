#!/bin/bash
set -e

echo "Starting Medusa server..."

# Set environment variables for runtime
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment configured:"
echo "HOST: 0.0.0.0"
echo "PORT: $PORT"
echo "NODE_ENV: $NODE_ENV"

# Only build if admin files don't exist (backup)
if [ ! -f ".medusa/server/public/admin/index.html" ]; then
    echo "Admin build files not found, building..."
    export NODE_OPTIONS='--max-old-space-size=512'
    npx medusa build
else
    echo "Admin build files found, skipping build"
fi

# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Start the server with explicit host and port
echo "Starting server on 0.0.0.0:${PORT:-9000}..."
npx medusa start --host 0.0.0.0 --port ${PORT:-9000}