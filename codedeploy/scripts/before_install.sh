#!/bin/bash
set -e
mkdir -p /opt/fooddash
if [ -f /opt/fooddash/.env ]; then
  cp /opt/fooddash/.env /tmp/fooddash.env.preserve
fi
rm -rf /opt/fooddash/*
if [ -f /tmp/fooddash.env.preserve ]; then
  mv /tmp/fooddash.env.preserve /opt/fooddash/.env
fi
chown -R ubuntu:ubuntu /opt/fooddash
