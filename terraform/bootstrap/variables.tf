# terraform/bootstrap/variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "fooddash"
}

variable "environment" {
  description = "Environment label (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "github_org" {
  description = "GitHub organisation or user name that owns the repository"
  type        = string
  # e.g. "my-org" or "my-username"
}

variable "github_repo" {
  description = "GitHub repository name (without the org prefix)"
  type        = string
  # e.g. "food-dash"
}

variable "deploy_branches" {
  description = "Branches allowed to assume the IAM role"
  type        = list(string)
  default     = ["main", "staging"]
}
