# terraform/main.tf
# Entry point: Terraform settings, provider configuration, and shared locals.
# Resources are split across purpose-named files:
#   network.tf     — VPC, subnets, IGW, routing
#   security.tf    — security groups
#   alb.tf         — Application Load Balancer
#   autoscaling.tf — launch template and ASG
#   iam.tf         — all IAM roles and policies
#   codedeploy.tf  — S3 artifact bucket and CodeDeploy resources
#   outputs.tf     — all outputs

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend values are passed via -backend-config flags in CI (see deploy.yml).
  # Run `terraform init -backend-config=...` locally or let the workflow do it.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}


