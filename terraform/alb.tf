# terraform/alb.tf
# Application Load Balancer, target group, and HTTP listener test

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public_subnet : s.id]

  enable_deletion_protection = false # Set true for production
  enable_http2               = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-alb" })
}

resource "aws_lb_target_group" "backend" {
  name                 = "${var.project_name}-backend-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.fooddash_vpc.id
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
    protocol            = "HTTP"
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-backend-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-http-listener" })
}
