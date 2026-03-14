#!/bin/bash
# scripts/setup.sh
set -e

# Update and install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get update
apt-get install -y nodejs git

# Install PM2 to keep the NestJS app running
npm install -g pm2

# Clone and setup the app (using a placeholder repo for now)
cd /home/ubuntu
# git clone https://github.com/YOUR_USER/FoodDash.git
# cd FoodDash/backend
# npm install
# npm run build
# pm2 start dist/main.js --name "fooddash-api"