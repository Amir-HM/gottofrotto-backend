#!/bin/bash
set -euo pipefail

# =============================================================================
# Gottofrotto Backend — Pull, build, and restart
# =============================================================================
# Run from the server:
#   sudo -u gottofrotto bash /opt/gottofrotto/deploy/update.sh
# =============================================================================

APP_DIR="/opt/gottofrotto"
cd "$APP_DIR"

echo "→ Pulling latest code..."
git pull origin master

echo "→ Installing dependencies..."
yarn install --immutable 2>&1 | tail -3

echo "→ Building..."
NODE_ENV=production NODE_OPTIONS='--max-old-space-size=1536' yarn build

echo "→ Running database migrations..."
npx medusa db:migrate

echo "→ Restarting service..."
sudo systemctl restart gottofrotto

echo "→ Checking service status..."
sleep 2
systemctl is-active gottofrotto && echo "✓ Service is running" || echo "✗ Service failed to start — check: sudo journalctl -u gottofrotto -n 50"
