#!/bin/bash
# EC2 bootstrap: Node, PM2, CodeDeploy agent (${aws_region})
set -e
export DEBIAN_FRONTEND=noninteractive

# Update and install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get update
apt-get install -y nodejs git ruby-full wget unzip

# Install AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# Install PM2 to keep the NestJS app running
npm install -g pm2

# Configure PM2 to auto-start on system boot (survives EC2 reboots)
# Run as root targeting the ubuntu user, which generates the systemd unit.
pm2 startup systemd -u ubuntu --hp /home/ubuntu

# CodeDeploy agent (Ubuntu)
cd /tmp
wget -q "https://aws-codedeploy-${aws_region}.s3.${aws_region}.amazonaws.com/latest/install"
chmod +x ./install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# App is deployed by CodeDeploy to /opt/fooddash — place DATABASE_URL etc. in /opt/fooddash/.env (e.g. via SSM or AMI)
