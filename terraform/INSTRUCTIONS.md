# FoodDash Infrastructure — Setup & Deployment Instructions

Complete guide for provisioning the AWS infrastructure and getting the CI/CD pipeline running.
Follow the steps in order the first time. After setup, only Steps 4–5 apply for routine use.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed locally
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed locally
- AWS admin credentials configured locally (`aws configure`)
- Your app pushed to a GitHub repository

---

## Step 1 — Run the bootstrap (one-time, your laptop)

The bootstrap creates the S3 bucket for Terraform state and the IAM role that
GitHub Actions will use. This is the only step that requires AWS credentials on
your machine. After this, everything runs in CI automatically.

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

Add these three variables (not Secrets — these are not sensitive):

| Variable | Value |
|---|---|
| `GHA_ROLE_ARN` | from bootstrap output `github_actions_role_arn` |
| `TF_STATE_BUCKET` | from bootstrap output `state_bucket_name` |
| `AWS_REGION` | `us-east-1` (or your chosen region) |

---

## Step 3 — Add app secrets to AWS SSM

Secrets never go in GitHub. They live in AWS SSM Parameter Store and are
fetched automatically by each EC2 instance at deploy time.

Run these commands with your AWS admin credentials:

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

# SQS queue URL (if used)
aws ssm put-parameter \
  --name /fooddash/AWS_SQS_QUEUE_URL \
  --value "https://sqs.us-east-1.amazonaws.com/..." \
  --type SecureString
```

The naming convention `/fooddash/<KEY>` is important.
The deploy script strips the prefix and writes `KEY=value` into the `.env` file on the instance.

To update a secret later:
```bash
aws ssm put-parameter --name /fooddash/DATABASE_URL --value "new-value" --type SecureString --overwrite
```

To list all current secrets:
```bash
aws ssm get-parameters-by-path --path /fooddash/ --with-decryption --query "Parameters[*].[Name,Value]" --output table
```

---

## Step 4 — Trigger the first deploy

Push any change to the `main` branch (or the configured `deploy_branch`).

The GitHub Actions workflow will:
1. Authenticate to AWS via OIDC (no stored credentials)
2. Run `terraform init` → `terraform plan` → `terraform apply` (provisions all infra)
3. Build the NestJS app
4. Upload the bundle to S3
5. Trigger a CodeDeploy deployment to the EC2 instances
6. Print the app URL

Monitor progress at: `https://github.com/YOUR_ORG/food-dash/actions`

---

## Step 5 — Add remaining GitHub Variables (after first deploy)

After the first successful deploy, copy these values from the Terraform job
output in the GitHub Actions log and add them as GitHub Variables.

These are fallbacks used by the deploy job when only app code changes
(skipping Terraform to save time):

| Variable | Where to find it |
|---|---|
| `CODEDEPLOY_BUCKET` | Terraform output `codedeploy_artifacts_bucket` |
| `CODEDEPLOY_APP` | Terraform output `codedeploy_application_name` |
| `CODEDEPLOY_DG` | Terraform output `codedeploy_deployment_group_name` |
| `APP_URL` | Terraform output `app_url` |

---

## Routine use

### Deploy app changes
Just push to `main`. Terraform is skipped (no `.tf` files changed).
Only the build → upload → CodeDeploy steps run (~3–5 min).

### Deploy infra changes
Edit any `.tf` file and push to `main`. Terraform will plan and apply,
then the app deploy runs after.

### View current Terraform state
```bash
cd terraform
terraform init \
  -backend-config="bucket=YOUR_TF_STATE_BUCKET" \
  -backend-config="key=fooddash/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true"

terraform show
```

### Destroy all infrastructure (e.g. end of week to save cost)
```bash
cd terraform
terraform destroy
```

> **Warning:** This deletes the ALB, ASG, EC2 instances, and S3 bucket.
> The SSM secrets and Terraform state bucket are unaffected.
> Re-running the deploy workflow will rebuild everything from scratch.

---

## Architecture reference

```
Internet
    │
    ▼
Application Load Balancer (port 80)
    │
    ├── us-east-1a: EC2 t3.micro
    └── us-east-1b: EC2 t3.micro
              │
              └── NestJS app (PM2, port 3000)
                  └── .env fetched from SSM at deploy time

GitHub Actions (OIDC → IAM role)
    → terraform apply (infra)
    → CodeDeploy (app bundle from S3)
```

## File structure

```
terraform/
  main.tf          — terraform block, provider, locals
  variables.tf     — all input variables
  outputs.tf       — all outputs
  network.tf       — VPC, subnets, IGW, routing
  security.tf      — security groups
  alb.tf           — Application Load Balancer
  autoscaling.tf   — launch template and ASG
  iam.tf           — IAM roles and policies
  codedeploy.tf    — S3 artifact bucket and CodeDeploy
  bootstrap/       — one-time setup (run locally once)
```
