#!/bin/bash
set -e

# ========================
# 1. START SSH (di background)
# ========================
echo "🛡️ Starting SSH server..."
/usr/local/bin/ssh-user-config.sh &
SSH_PID=$!

# ========================
# 2. SETUP JOURNIV
# ========================
cd /app/journiv-app
source .venv/bin/activate

# Migrasi database
echo "📦 Running database migrations..."
alembic upgrade head

# ========================
# 3. START CLOUDFLARED (opsional)
# ========================
if [ -n "$CLOUDFLARED_TOKEN" ]; then
    echo "🌐 Starting Cloudflared tunnel..."
    cloudflared tunnel --url http://localhost:8000 &
fi

# ========================
# 4. START JOURNIV (foreground)
# ========================
echo "📖 Starting Journiv on port 8000..."
exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --proxy-headers \
    --forwarded-allow-ips='*'
