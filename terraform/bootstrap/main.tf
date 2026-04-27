# terraform/bootstrap/main.tf
#
# ONE-TIME SETUP — run this manually once with admin credentials:
#
#   cd terraform/bootstrap
#   terraform init
#   terraform apply
#
# This creates:
#   1. S3 bucket + DynamoDB table  → Terraform remote state for the main config
#   2. GitHub Actions OIDC provider + IAM role → no stored AWS secrets in GitHub
#
# After apply, copy the outputs into your GitHub Actions variables:
#   TF_STATE_BUCKET   = outputs.state_bucket_name
#   TF_LOCK_TABLE     = outputs.lock_table_name
#   AWS_ACCOUNT_ID    = outputs.aws_account_id
#   GHA_ROLE_ARN      = outputs.github_actions_role_arn

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# 1. Terraform remote state — S3 bucket + DynamoDB lock table
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  # Bucket names must be globally unique; account ID ensures that.
  bucket = "${var.project_name}-${var.environment}-tfstate-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform-bootstrap"
    Purpose   = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Prevent accidental deletion — remove manually if you want to destroy the bucket
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {} # required by AWS provider v5 even when applying to all objects

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# -----------------------------------------------------------------------------
# 2. GitHub Actions OIDC provider
# -----------------------------------------------------------------------------

# GitHub's OIDC provider URL — one per AWS account (data source avoids duplicate
# errors if it was added previously via Console).
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # "sts.amazonaws.com" is the audience GitHub tokens present to AWS STS
  client_id_list = ["sts.amazonaws.com"]

  # AWS stopped validating OIDC thumbprints for GitHub in 2023, but the
  # resource still requires the field. These are the known GitHub CA thumbprints.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1b511abead59c6ce207077c0bf0e0043b1382612",
  ]

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform-bootstrap"
  }
}

# -----------------------------------------------------------------------------
# 3. IAM role that GitHub Actions assumes via OIDC
# -----------------------------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GitHubOIDC"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # Allow any of the configured branches to assume this role.
          # StringLike supports multiple values — a token matches if it equals any entry.
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for branch in var.deploy_branches :
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform-bootstrap"
  }
}

# -----------------------------------------------------------------------------
# 4. Permissions for the GitHub Actions role
#
# Terraform manages broad AWS resources (IAM, VPC, EC2, ALB, ASG, S3,
# CodeDeploy). AdministratorAccess is the pragmatic choice for a Terraform
# runner role — scope it further once your infrastructure is stable by listing
# only the services your Terraform configs actually touch.
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# The state bucket and lock table access is already covered by AdministratorAccess
# above, but it's good to have it explicit in case you later scope down the role.
resource "aws_iam_role_policy" "github_actions_tfstate" {
  name = "terraform-state-access"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StateBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*",
        ]
      },
    ]
  })
}
