#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

BUILD_DIR=".medusa/server"
if [ ! -d "$BUILD_DIR" ]; then
  echo "Build not found at $BUILD_DIR, building..."
  NODE_OPTIONS='--max-old-space-size=1536' npm run build

  echo "Verifying admin build..."
  if [ -f "public/admin/index.html" ]; then
      echo "Admin UI build successful"
  else
      echo "Warning: Admin UI index.html not found"
  fi
fi

exec medusa start --host 0.0.0.0 --port ${PORT:-9000}
