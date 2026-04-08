# terraform/outputs.tf
# All outputs are consolidated here.

output "app_url" {
  description = "URL to access the application (HTTP)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB (useful for DNS alias records)"
  value       = aws_lb.main.zone_id
}

output "codedeploy_artifacts_bucket" {
  description = "S3 bucket where CI uploads deployment zips"
  value       = aws_s3_bucket.codedeploy_artifacts.bucket
}

output "codedeploy_application_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.backend.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.backend.deployment_group_name
}
