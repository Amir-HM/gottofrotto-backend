#!/bin/bash
set -e

# Start script only — the build is already done by Railway's build phase
# (npm install + npm run build) before the runtime container starts.
# This script just verifies the build output, runs migrations, then exec's
# the server. Keeps build noise out of the runtime log stream.

BUILD_DIR=".medusa/server"
if [ ! -d "$BUILD_DIR" ]; then
  echo "❌ Build output not found at $BUILD_DIR — did the build phase fail?"
  exit 1
fi

if [ ! -f "public/admin/index.html" ]; then
  echo "❌ Admin UI build missing (public/admin/index.html)"
  exit 1
fi

# Use the resolved binary instead of `npx` to skip its 2–4 s package-bin
# lookup on every cold start. The migrate is still a no-op when the schema
# is current, but it's our last line of defense against drift.
./node_modules/.bin/medusa db:migrate

exec ./node_modules/.bin/medusa start --host 0.0.0.0 --port ${PORT:-9000}
