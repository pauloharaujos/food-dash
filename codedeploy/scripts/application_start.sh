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
pm2 start dist/src/main.js --name fooddash-api
pm2 save

# Wait a moment and verify the process is still running (didn't crash immediately)
sleep 5
if ! pm2 show fooddash-api | grep -q "online"; then
  echo "ERROR: fooddash-api crashed on startup. Last logs:" >&2
  pm2 logs fooddash-api --lines 30 --nostream >&2
  exit 1
fi
