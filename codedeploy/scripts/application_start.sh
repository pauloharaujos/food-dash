#!/bin/bash
set -e
cd /opt/fooddash
if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi
export PORT="${PORT:-3000}"
export HOME=/home/ubuntu
pm2 delete fooddash-api 2>/dev/null || true
pm2 start dist/main.js --name fooddash-api
pm2 save
