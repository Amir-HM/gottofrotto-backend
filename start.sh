#!/bin/bash
set -e

echo "=== Starting Gottofrotto Backend API ==="
echo "NODE_ENV: ${NODE_ENV:-development}"
echo "PORT: ${PORT:-9000}"

# Build application with admin UI (includes symbolic link creation)
echo "Building application (backend + admin UI)..."
NODE_OPTIONS='--max-old-space-size=1536' npm run build

# Verify admin files are accessible
echo "Verifying admin build..."
if [ -f "public/admin/index.html" ]; then
    echo "✅ Admin UI build successful - index.html found at public/admin/index.html"
else
    echo "❌ Admin UI build failed - index.html not found"
    ls -la public/ 2>/dev/null || echo "No public directory"
fi

# Start server (migrations already completed)
echo "Starting Medusa API server..."
exec medusa start --host 0.0.0.0 --port ${PORT:-9000}