#!/bin/bash
set -eo pipefail
export PATH=$PATH:/usr/local/bin:/usr/bin

# Pull all secrets stored under /fooddash/* in SSM Parameter Store.
# Each parameter name becomes the env var key: /fooddash/DATABASE_URL → DATABASE_URL=...
# Add secrets via: aws ssm put-parameter --name /fooddash/DATABASE_URL --value '...' --type SecureString
REGION=$(curl -sf http://169.254.169.254/latest/meta-data/placement/region || echo "us-east-1")
aws ssm get-parameters-by-path \
  --path "/fooddash/" \
  --with-decryption \
  --recursive \
  --query "Parameters[*].[Name,Value]" \
  --output text \
  --region "$REGION" | while IFS=$'\t' read -r name value; do
    key="${name##*/}"
    printf '%s=%s\n' "$key" "$value"
  done > .env

if [ ! -s .env ]; then
  echo "ERROR: .env is empty — SSM fetch failed or /fooddash/ has no parameters" >&2
  exit 1
fi

npm ci --omit=dev --ignore-scripts
rm -rf prisma/generated
npx prisma generate
npx prisma migrate deploy
