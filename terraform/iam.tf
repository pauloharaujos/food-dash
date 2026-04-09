# terraform/iam.tf
# All IAM roles, policies, and instance profiles

# -----------------------------------------------------------------------------
# EC2 instance role
# Grants instances permission to: pull CodeDeploy bundles from S3,
# read app secrets from SSM, and use SSM Session Manager (no port 22 needed).
# -----------------------------------------------------------------------------

resource "aws_iam_role" "backend_ec2" {
  name_prefix = "${var.project_name}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, { Name = "${var.project_name}-ec2-role" })
}

resource "aws_iam_role_policy" "backend_ec2_codedeploy_s3" {
  name_prefix = "codedeploy-s3-"
  role        = aws_iam_role.backend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ArtifactBundleRead"
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:GetObjectVersion",
      ]
      Resource = "${aws_s3_bucket.codedeploy_artifacts.arn}/deployments/*"
    }]
  })
}

resource "aws_iam_role_policy" "backend_ec2_ssm" {
  name_prefix = "ssm-params-"
  role        = aws_iam_role.backend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "SSMSecretsRead"
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath",
      ]
      Resource = "arn:aws:ssm:*:*:parameter/fooddash/*"
    }]
  })
}

# Enables SSM Session Manager — shell access to instances without opening port 22
resource "aws_iam_role_policy_attachment" "backend_ec2_ssm_core" {
  role       = aws_iam_role.backend_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "backend_ec2" {
  name_prefix = "${var.project_name}-ec2-"
  role        = aws_iam_role.backend_ec2.name

  tags = merge(local.common_tags, { Name = "${var.project_name}-ec2-profile" })
}

# -----------------------------------------------------------------------------
# CodeDeploy service role
# Allows CodeDeploy to manage EC2 instances in the ASG and deregister/register
# them from the ALB target group during in-place deployments.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "codedeploy" {
  name_prefix = "${var.project_name}-codedeploy-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, { Name = "${var.project_name}-codedeploy-role" })
}

resource "aws_iam_role_policy_attachment" "codedeploy_ec2" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}


