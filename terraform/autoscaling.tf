# terraform/autoscaling.tf
# Launch template and Auto Scaling Group for backend EC2 instances

# Latest Ubuntu 22.04 LTS AMI (Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_ec2.name
  }

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = base64encode(templatefile("${path.module}/scripts/setup.sh.tpl", { aws_region = var.aws_region }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-backend"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.project_name}-backend-asg"
  vpc_zone_identifier       = [for s in aws_subnet.public_subnet : s.id]
  target_group_arns         = [aws_lb_target_group.backend.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
