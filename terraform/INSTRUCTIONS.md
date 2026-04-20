# FoodDash Infrastructure — Setup & Deployment Guide

Infrastructure is split into two independent Terraform modules — `terraform/backend/` and `terraform/frontend/` — each with its own remote state and CI/CD workflow.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed locally
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed locally
- AWS admin credentials configured locally (`aws configure`)
- Your app pushed to a GitHub repository

---

## Step 1 — Run the bootstrap (one-time)

The bootstrap creates the S3 bucket for Terraform state and the IAM role GitHub Actions uses. This is the only step that requires local AWS credentials.

```bash
cd terraform/bootstrap
terraform init

terraform apply \
  -var="github_org=YOUR_GITHUB_USERNAME" \
  -var="github_repo=food-dash" \
  -var='deploy_branches=["main","staging","feature/implement-terraform-for-aws-infrastructure"]'
```

When it finishes, note the three output values — you'll need them in Step 2:

```
github_actions_role_arn = "arn:aws:iam::123456789::role/fooddash-github-actions"
state_bucket_name       = "fooddash-dev-tfstate-123456789"
aws_account_id          = "123456789"
```

> The bootstrap is idempotent — safe to run again if something goes wrong.

---

## Step 2 — Add GitHub Variables

Go to your repository → **Settings → Variables → Actions → New repository variable**

| Variable | Value |
|---|---|
| `GHA_ROLE_ARN` | from bootstrap output `github_actions_role_arn` |
| `TF_STATE_BUCKET` | from bootstrap output `state_bucket_name` |
| `AWS_REGION` | `us-east-1` (or your chosen region) |

---

## Step 3 — Add app secrets to AWS SSM

Secrets live in AWS SSM Parameter Store and are fetched by each EC2 instance at deploy time.

```bash
# Database connection string
aws ssm put-parameter \
  --name /fooddash/DATABASE_URL \
  --value "postgresql://user:password@host:5432/fooddash?schema=public" \
  --type SecureString

# App port (must match var.app_port in variables.tf — default 3000)
aws ssm put-parameter \
  --name /fooddash/PORT \
  --value "3000" \
  --type SecureString

# Node environment
aws ssm put-parameter \
  --name /fooddash/NODE_ENV \
  --value "production" \
  --type SecureString

> The SQS queue URL and Redis endpoint are **not known until after `terraform apply` runs** (Step 4). Add them afterwards — see Step 5b below.



The naming convention `/fooddash/<KEY>` strips the prefix and writes `KEY=value` into `.env` on each instance.

To update a secret:
```bash
aws ssm put-parameter --name /fooddash/DATABASE_URL --value "new-value" --type SecureString --overwrite
```

To list all secrets:
```bash
aws ssm get-parameters-by-path --path /fooddash/ --with-decryption --query "Parameters[*].[Name,Value]" --output table
```

---

## Step 4 — Trigger the first deploy

Push to the configured branch. The `deploy-backend.yml` workflow will:
1. Authenticate to AWS via OIDC
2. Run `terraform apply` inside `terraform/backend/` (provisions VPC, ALB, ASG, CodeDeploy)
3. Build the NestJS app, upload the bundle to S3, and trigger a CodeDeploy deployment

The `deploy-frontend.yml` workflow will:
1. Run `terraform apply` inside `terraform/frontend/` (provisions S3 bucket + CloudFront)
2. Build the Vite app, sync assets to S3, and invalidate the CloudFront cache

Monitor progress at: `https://github.com/YOUR_ORG/food-dash/actions`

---

## Step 5 — Add fallback GitHub Variables (after first deploy)

After the first deploy, copy these values from the Terraform job output and add them as GitHub Variables. They're used as fallbacks when only app code changes (skipping Terraform).

**Backend**

| Variable | Source |
|---|---|
| `BACKEND_CODEDEPLOY_BUCKET` | `terraform/backend` output `codedeploy_artifacts_bucket` |
| `BACKEND_CODEDEPLOY_APP` | `terraform/backend` output `codedeploy_application_name` |
| `BACKEND_CODEDEPLOY_DG` | `terraform/backend` output `codedeploy_deployment_group_name` |
| `BACKEND_APP_URL` | `terraform/backend` output `app_url` |

**Frontend**

| Variable | Source |
|---|---|
| `FRONTEND_BUCKET` | `terraform/frontend` output `frontend_bucket_name` |
| `FRONTEND_CLOUDFRONT_DIST_ID` | `terraform/frontend` output `cloudfront_distribution_id` |
| `FRONTEND_CLOUDFRONT_URL` | `terraform/frontend` output `cloudfront_url` |
| `FRONTEND_VITE_GRAPHQL_HTTP_URL` | Your ALB URL + `/graphql` |
| `FRONTEND_VITE_GRAPHQL_WS_URL` | Your ALB URL + `/graphql` (ws://) |

---

## Step 5b — Add SQS and Redis SSM parameters (after first deploy)

After `terraform apply` completes, the SQS queue URL and Redis endpoint are available as Terraform outputs. Run the following to store them in SSM so the app can read them at runtime:

```bash
# Get the values from Terraform output
cd terraform/backend
SQS_URL=$(terraform output -raw sqs_orders_queue_url)
REDIS_HOST=$(terraform output -raw redis_endpoint)
REDIS_PORT=$(terraform output -raw redis_port)

# Store in SSM Parameter Store
aws ssm put-parameter \
  --name /fooddash/AWS_SQS_QUEUE_URL \
  --value "$SQS_URL" \
  --type SecureString \
  --region us-east-1

aws ssm put-parameter \
  --name /fooddash/REDIS_HOST \
  --value "$REDIS_HOST" \
  --type SecureString \
  --region us-east-1

aws ssm put-parameter \
  --name /fooddash/REDIS_PORT \
  --value "$REDIS_PORT" \
  --type SecureString \
  --region us-east-1
```

To update any of them later:
```bash
aws ssm put-parameter --name /fooddash/REDIS_HOST --value "new-value" --type SecureString --overwrite
```

> No new GitHub Variables are required — the EC2 instances already fetch all `/fooddash/*` parameters from SSM at deploy time via the existing IAM policy.

### Step 5b — Redeploy after storing SSM parameters

The first deployment (Step 4) ran before these SSM parameters existed, so the running instances have a `.env` missing `AWS_SQS_QUEUE_URL`, `REDIS_HOST`, and `REDIS_PORT`. Trigger a new deployment to pick them up:

Once the CodeDeploy deployment completes, `after_install.sh` will re-fetch all `/fooddash/*` parameters from SSM and write the complete `.env` to each instance.

To trigger the redeploy via the GitHub Actions UI:
1. Go to your repository → **Actions**
2. Select the **Deploy Backend** workflow
3. Click **Run workflow**, choose the target branch, and confirm

---

## Testing the frontend

> **⚠️ Warning — Mixed content during testing**
>
> The frontend is served over HTTPS (CloudFront) but the backend ALB does not have an SSL certificate, so its GraphQL endpoint is HTTP only. Browsers block HTTPS pages from making HTTP requests (mixed content policy), which causes "Failed to fetch" errors in the Order Dashboard.
>
> This is a **local testing workaround only** and does not affect production (which should have a custom domain + SSL on the ALB).
>
> To allow it in Chrome for your session:
> 1. Go to `chrome://flags/#unsafely-treat-insecure-origin-as-secure`
> 2. Add your CloudFront URL (e.g. `https://d39too7dg51py8.cloudfront.net`) to the list
> 3. Set the flag to **Enabled** and relaunch Chrome

---

## Routine use

### Deploy backend changes
Push changes under `src/`, `prisma/`, or `codedeploy/`. Terraform is skipped; only the build → CodeDeploy steps run (~3–5 min).

### Deploy frontend changes
Push changes under `frontend/`. Only the build → S3 sync → CloudFront invalidation steps run (~2 min).

### Deploy infrastructure changes
Edit files under `terraform/backend/` or `terraform/frontend/` and push. Terraform will plan and apply, then the corresponding deploy step runs.

### View current Terraform state

```bash
# Backend
cd terraform/backend
terraform init \
  -backend-config="bucket=YOUR_TF_STATE_BUCKET" \
  -backend-config="key=fooddash/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true"
terraform show

# Frontend
cd terraform/frontend
terraform init \
  -backend-config="bucket=YOUR_TF_STATE_BUCKET" \
  -backend-config="key=fooddash/frontend.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true"
terraform show
```

### Destroy infrastructure
```bash
cd terraform/backend && terraform destroy
cd terraform/frontend && terraform destroy
```

---

## Architecture

```
Users
 ├── CloudFront (d1abc.cloudfront.net) → S3 bucket   [Frontend — React/Vite]
 └── ALB (fooddash-alb-xxx.us-east-1.elb.amazonaws.com)
      ├── us-east-1a: EC2 t3.micro
      └── us-east-1b: EC2 t3.micro
               └── NestJS (PM2, port 3000)
                   └── .env ← SSM at deploy time

GitHub Actions (OIDC → IAM role)
 ├── deploy-backend.yml → terraform/backend + CodeDeploy
 └── deploy-frontend.yml → terraform/frontend + S3 sync
```

## Terraform structure

```
terraform/
  backend/
    main.tf          — provider, locals
    variables.tf
    outputs.tf
    network.tf       — VPC, subnets, IGW
    security.tf      — security groups
    alb.tf           — ALB, target group, listener
    autoscaling.tf   — launch template, ASG
    iam.tf           — EC2 + CodeDeploy IAM roles
    codedeploy.tf    — S3 artifact bucket, CodeDeploy app/dg
    scripts/         — EC2 user data
  frontend/
    main.tf          — provider, locals
    variables.tf
    outputs.tf
    s3.tf            — private S3 bucket
    cdn.tf           — CloudFront distribution + OAC
  bootstrap/         — one-time setup (run locally once)
```
