resource "aws_sqs_queue" "orders_dlq" {
  name                      = "${var.project_name}-orders-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 days

  tags = merge(local.common_tags, { Name = "${var.project_name}-orders-dlq" })
}

resource "aws_sqs_queue" "orders" {
  name                       = "${var.project_name}-orders-${var.environment}"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400 # 1 day

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orders_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge(local.common_tags, { Name = "${var.project_name}-orders" })
}
