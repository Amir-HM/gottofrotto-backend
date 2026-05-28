#!/bin/bash
set -e

# Start script only — the build is already done by Railway's build phase
# (npm install + npm run build) before the runtime container starts.
# This script just verifies the build output, runs migrations, then exec's
# the server. Keeps build noise out of the runtime log stream.

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

BUILD_DIR=".medusa/server"
if [ ! -d "$BUILD_DIR" ]; then
  echo "❌ Build output not found at $BUILD_DIR — did the build phase fail?"
  exit 1
fi

if [ ! -f "public/admin/index.html" ]; then
  echo "❌ Admin UI build missing (public/admin/index.html)"
  ls -la public/ 2>/dev/null || echo "  no public/ directory"
  exit 1
fi
echo "✅ Build output present"

echo "Running database migrations..."
npx medusa db:migrate

echo "Starting Medusa API server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}
