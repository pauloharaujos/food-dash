# terraform/frontend/outputs.tf

output "cloudfront_url" {
  description = "HTTPS URL of the CloudFront distribution (use this to access the frontend)"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudfront_domain_name" {
  description = "Bare CloudFront domain name (without https://)"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed for cache invalidations after deploys"
  value       = aws_cloudfront_distribution.frontend.id
}

output "frontend_bucket_name" {
  description = "S3 bucket that holds the built static assets"
  value       = aws_s3_bucket.frontend.bucket
}
