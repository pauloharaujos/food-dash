data "aws_caller_identity" "current" {}

locals {
  codedeploy_bucket = lower("${var.project_name}-${var.environment}-codedeploy-${data.aws_caller_identity.current.account_id}")
}

resource "aws_s3_bucket" "codedeploy_artifacts" {
  bucket = local.codedeploy_bucket

  tags = merge(local.common_tags, { Name = "${var.project_name}-codedeploy-artifacts" })
}

resource "aws_s3_bucket_public_access_block" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_codedeploy_app" "backend" {
  name             = "${var.project_name}-backend"
  compute_platform = "Server"

  tags = merge(local.common_tags, { Name = "${var.project_name}-codedeploy-app" })
}

resource "aws_codedeploy_deployment_group" "backend" {
  app_name              = aws_codedeploy_app.backend.name
  deployment_group_name = "${var.project_name}-backend-dg"
  service_role_arn      = aws_iam_role.codedeploy.arn
  autoscaling_groups    = [aws_autoscaling_group.backend.name]

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.backend.name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-codedeploy-dg" })
}
