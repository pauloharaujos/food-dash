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
PATH_CHECK="${HEALTH_CHECK_PATH:-/health}"

# Retry for up to 30 seconds to give the app time to start
for i in $(seq 1 10); do
  if curl -sf "http://127.0.0.1:${PORT}${PATH_CHECK}" >/dev/null; then
    echo "App is healthy on port ${PORT}"
    exit 0
  fi
  echo "Attempt $i/10: app not ready yet, waiting 3s..."
  sleep 3
done

echo "ERROR: App did not respond on port ${PORT} after 30 seconds" >&2
exit 1
