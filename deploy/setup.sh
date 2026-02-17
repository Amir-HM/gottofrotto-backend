#!/bin/bash
set -euo pipefail

# =============================================================================
# Gottofrotto Backend — Debian Server Setup
# =============================================================================
# Run as root on a fresh Debian 12+ machine:
#   sudo bash deploy/setup.sh
#
# Prerequisites:
#   - Debian 12 (Bookworm) or later
#   - Root/sudo access
#   - Domain DNS A record pointing to this machine's public IP
# =============================================================================

DOMAIN="your-domain.com"          # <-- CHANGE THIS
REPO_URL="https://github.com/your-org/gottofrotto-backend.git"  # <-- CHANGE THIS
BRANCH="master"
APP_DIR="/opt/gottofrotto"
APP_USER="gottofrotto"
NODE_VERSION="20"
DB_NAME="gottofrotto"
DB_USER="gottofrotto"
BACKUP_DIR="/var/backups/gottofrotto"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
info()  { echo -e "\n\033[1;34m→ $*\033[0m"; }
ok()    { echo -e "\033[1;32m  ✓ $*\033[0m"; }
fail()  { echo -e "\033[1;31m  ✗ $*\033[0m"; exit 1; }

if [ "$DOMAIN" = "your-domain.com" ]; then
  fail "Edit this script and set DOMAIN before running."
fi

if [ "$REPO_URL" = "https://github.com/your-org/gottofrotto-backend.git" ]; then
  fail "Edit this script and set REPO_URL before running."
fi

# -----------------------------------------------------------------------------
# 1. System packages
# -----------------------------------------------------------------------------
info "Updating system packages"
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq curl git build-essential snapd
ok "System packages up to date"

# -----------------------------------------------------------------------------
# 2. PostgreSQL
# -----------------------------------------------------------------------------
info "Installing PostgreSQL"
apt-get install -y -qq postgresql postgresql-contrib
systemctl enable postgresql
systemctl start postgresql
ok "PostgreSQL $(pg_config --version 2>/dev/null || echo 'installed')"

info "Creating database and user"
DB_PASS=$(openssl rand -hex 16)

# Create user and database if they don't exist
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_databases WHERE datname='${DB_NAME}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
ok "Database '${DB_NAME}' ready"

# -----------------------------------------------------------------------------
# 3. PostgreSQL backups
# -----------------------------------------------------------------------------
info "Setting up automated database backups"
mkdir -p "$BACKUP_DIR"
chown postgres:postgres "$BACKUP_DIR"

cp "${APP_DIR:+/dev/null}" /dev/null 2>/dev/null || true  # no-op, APP_DIR might not exist yet

# We'll install the backup script and cron after cloning the repo (step 7)
ok "Backup directory created at ${BACKUP_DIR}"

# -----------------------------------------------------------------------------
# 4. Node.js 20
# -----------------------------------------------------------------------------
info "Installing Node.js ${NODE_VERSION}"
if ! command -v node &>/dev/null || ! node -v | grep -q "v${NODE_VERSION}"; then
  curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
  apt-get install -y -qq nodejs
fi
ok "Node.js $(node -v)"

# -----------------------------------------------------------------------------
# 5. Enable Yarn via Corepack
# -----------------------------------------------------------------------------
info "Enabling Yarn via Corepack"
corepack enable
ok "Corepack enabled"

# -----------------------------------------------------------------------------
# 6. Create app user
# -----------------------------------------------------------------------------
info "Creating application user: ${APP_USER}"
if ! id "$APP_USER" &>/dev/null; then
  useradd --system --create-home --home-dir "$APP_DIR" --shell /bin/bash "$APP_USER"
  ok "User created"
else
  ok "User already exists"
fi

# -----------------------------------------------------------------------------
# 7. Clone / update repository
# -----------------------------------------------------------------------------
info "Setting up application at ${APP_DIR}"
if [ -d "${APP_DIR}/.git" ]; then
  sudo -u "$APP_USER" git -C "$APP_DIR" fetch origin
  sudo -u "$APP_USER" git -C "$APP_DIR" checkout "$BRANCH"
  sudo -u "$APP_USER" git -C "$APP_DIR" pull origin "$BRANCH"
  ok "Repository updated"
else
  if [ -d "$APP_DIR" ] && [ ! -d "${APP_DIR}/.git" ]; then
    # Directory exists but isn't a git repo (created by useradd)
    chown "$APP_USER:$APP_USER" "$APP_DIR"
    sudo -u "$APP_USER" git clone --branch "$BRANCH" "$REPO_URL" "${APP_DIR}/app"
    # Move contents up
    sudo -u "$APP_USER" bash -c "shopt -s dotglob && mv ${APP_DIR}/app/* ${APP_DIR}/ && rmdir ${APP_DIR}/app"
  else
    sudo -u "$APP_USER" git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
  fi
  ok "Repository cloned"
fi

# -----------------------------------------------------------------------------
# 8. Install backup script and cron
# -----------------------------------------------------------------------------
info "Installing backup cron job"
cp "${APP_DIR}/deploy/backup.sh" /usr/local/bin/gottofrotto-backup
chmod +x /usr/local/bin/gottofrotto-backup

# Daily backup at 3 AM, keep 7 days
CRON_LINE="0 3 * * * /usr/local/bin/gottofrotto-backup"
(sudo -u postgres crontab -l 2>/dev/null | grep -v gottofrotto-backup; echo "$CRON_LINE") | sudo -u postgres crontab -
ok "Daily backup cron installed (3 AM, 7-day retention)"

# -----------------------------------------------------------------------------
# 9. Install dependencies and build
# -----------------------------------------------------------------------------
info "Installing dependencies"
cd "$APP_DIR"
sudo -u "$APP_USER" yarn install --immutable 2>&1 | tail -3
ok "Dependencies installed"

info "Building application"
sudo -u "$APP_USER" bash -c "cd ${APP_DIR} && NODE_ENV=production NODE_OPTIONS='--max-old-space-size=1536' yarn build"
ok "Build complete"

# -----------------------------------------------------------------------------
# 10. Environment file
# -----------------------------------------------------------------------------
info "Setting up environment file"
ENV_FILE="${APP_DIR}/.env"
if [ ! -f "$ENV_FILE" ]; then
  JWT=$(openssl rand -hex 32)
  COOKIE=$(openssl rand -hex 32)
  cat > "$ENV_FILE" <<ENVEOF
NODE_ENV=production

# Database (local PostgreSQL)
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}

# CORS
STORE_CORS=https://${DOMAIN}
ADMIN_CORS=https://${DOMAIN}
AUTH_CORS=https://${DOMAIN}

# Secrets (auto-generated)
JWT_SECRET=${JWT}
COOKIE_SECRET=${COOKIE}

# Resend email
# RESEND_API_KEY=re_xxxxxxxxxxxx
# RESEND_FROM=noreply@${DOMAIN}

# Password reset URL
ADMIN_RESET_PASSWORD_URL=https://${DOMAIN}/app/reset-password

# Server
PORT=9000
ENVEOF
  chown "$APP_USER:$APP_USER" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  ok "Environment file created at ${ENV_FILE} (DB credentials auto-configured)"
else
  ok "Environment file already exists"
fi

# -----------------------------------------------------------------------------
# 11. systemd service
# -----------------------------------------------------------------------------
info "Installing systemd service"
cp "${APP_DIR}/deploy/gottofrotto.service" /etc/systemd/system/gottofrotto.service
systemctl daemon-reload
systemctl enable gottofrotto
ok "Service installed and enabled"

# -----------------------------------------------------------------------------
# 12. nginx
# -----------------------------------------------------------------------------
info "Installing nginx"
apt-get install -y -qq nginx
ok "nginx installed"

info "Configuring nginx"
sed "s/\${DOMAIN}/${DOMAIN}/g" "${APP_DIR}/deploy/nginx.conf" > /etc/nginx/sites-available/gottofrotto
ln -sf /etc/nginx/sites-available/gottofrotto /etc/nginx/sites-enabled/gottofrotto
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
ok "nginx configured"

# -----------------------------------------------------------------------------
# 13. SSL via Let's Encrypt
# -----------------------------------------------------------------------------
info "Setting up SSL with Let's Encrypt"
if ! command -v certbot &>/dev/null; then
  snap install --classic certbot 2>/dev/null || apt-get install -y -qq certbot python3-certbot-nginx
  ln -sf /snap/bin/certbot /usr/bin/certbot 2>/dev/null || true
fi
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect
ok "SSL certificate obtained"

# -----------------------------------------------------------------------------
# 14. Firewall
# -----------------------------------------------------------------------------
info "Configuring firewall"
if command -v ufw &>/dev/null; then
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
  ok "UFW firewall configured"
else
  ok "UFW not installed, skipping (configure iptables manually if needed)"
fi

# -----------------------------------------------------------------------------
# 15. Run database migrations
# -----------------------------------------------------------------------------
info "Running database migrations"
sudo -u "$APP_USER" bash -c "cd ${APP_DIR} && source .env && npx medusa db:migrate"
ok "Migrations complete"

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "  PostgreSQL:"
echo "    Database: ${DB_NAME}"
echo "    User:     ${DB_USER}"
echo "    Backups:  ${BACKUP_DIR} (daily at 3 AM, 7-day retention)"
echo ""
echo "  Next steps:"
echo "  1. (Optional) Edit ${ENV_FILE}"
echo "     - Set RESEND_API_KEY if using email"
echo "     - Adjust CORS domains if your frontend is on a different domain"
echo ""
echo "  2. Start the service:"
echo "     sudo systemctl start gottofrotto"
echo ""
echo "  3. Check status:"
echo "     sudo systemctl status gottofrotto"
echo "     sudo journalctl -u gottofrotto -f"
echo ""
echo "  Your site will be live at: https://${DOMAIN}"
echo "  Admin dashboard: https://${DOMAIN}/app"
echo ""
