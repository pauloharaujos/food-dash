# terraform/bootstrap/outputs.tf
# Copy these values into GitHub Actions → Settings → Variables

output "aws_account_id" {
  description = "AWS account ID — set as GitHub Actions variable AWS_ACCOUNT_ID"
  value       = data.aws_caller_identity.current.account_id
}

output "state_bucket_name" {
  description = "S3 bucket for Terraform state — set as GitHub Actions variable TF_STATE_BUCKET"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC — set as GitHub Actions variable GHA_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
