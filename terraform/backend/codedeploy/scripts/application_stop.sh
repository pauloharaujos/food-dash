#!/bin/bash
set -e
if id ubuntu &>/dev/null; then
  sudo -u ubuntu bash -c 'export HOME=/home/ubuntu; pm2 stop fooddash-api 2>/dev/null || true'
fi
