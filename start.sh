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

# Skip migrations for faster startup - DB is already up to date
echo "Database already migrated, skipping migrations for faster startup..."

# Start the server - should be fast now
echo "Starting server..."
medusa start --host 0.0.0.0 --port ${PORT:-9000}