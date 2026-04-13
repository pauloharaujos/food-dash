#!/bin/bash
set -e

# Ensure swap exists to prevent OOM kills during npm ci on low-memory instances
if [ ! -f /swapfile ]; then
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
fi

mkdir -p /opt/fooddash
if [ -f /opt/fooddash/.env ]; then
  cp /opt/fooddash/.env /tmp/fooddash.env.preserve
fi
rm -rf /opt/fooddash/*
if [ -f /tmp/fooddash.env.preserve ]; then
  mv /tmp/fooddash.env.preserve /opt/fooddash/.env
fi
chown ubuntu:ubuntu /opt/fooddash
[ -f /opt/fooddash/.env ] && chown ubuntu:ubuntu /opt/fooddash/.env || true
