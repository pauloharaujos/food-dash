# variables.tf - Configurable values

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type for backend servers"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Port the NestJS application listens on"
  type        = number
  default     = 3000
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access (restrict in production)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "fooddash"
}

variable "health_check_path" {
  description = "Path for ALB target group health checks"
  type        = string
  default     = "/health"
}
