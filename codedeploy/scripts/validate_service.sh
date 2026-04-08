#!/bin/bash
set -e
cd /opt/fooddash
if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi
PORT="${PORT:-3000}"
PATH_CHECK="${HEALTH_CHECK_PATH:-/}"
curl -sf "http://127.0.0.1:${PORT}${PATH_CHECK}" >/dev/null
