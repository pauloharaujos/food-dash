# FoodDash Terraform Infrastructure

## Architecture

- **VPC** with 2 public subnets (multi-AZ: us-east-1a, us-east-1b)
- **Application Load Balancer (ALB)** distributing traffic across instances
- **Auto Scaling Group (ASG)** with 2–4 EC2 instances (configurable)
- **ElastiCache (Redis)** for pub/sub and caching (GraphQL subscriptions)
- **SQS** queue for asynchronous order processing
- **Security groups** with defense in depth: instances accept traffic only from ALB on port 3000; Redis accepts traffic only from EC2 instances on port 6379

## Networking design decision

In a production-grade setup, EC2 instances and ElastiCache should live in **private subnets**, with outbound internet access routed through a **NAT Gateway**. This prevents the instances and Redis from being directly reachable from the public internet.

However, a NAT Gateway costs ~$32/month plus data transfer fees, which is significant for a project at this stage. To keep costs low, **EC2 instances and ElastiCache are placed in public subnets** instead. The exposure risk is mitigated by security groups:

- Redis is not accessible from the internet — only from the backend EC2 security group on port 6379.
- EC2 instances only accept application traffic from the ALB and SSH from a restricted CIDR.

When moving to a production environment with stricter compliance requirements, the recommended path is:
1. Add private subnets to the VPC.
2. Move EC2 instances (via the launch template) and the ElastiCache subnet group to the private subnets.
3. Provision a NAT Gateway in the public subnet so private instances can still reach the internet (for SSM, ECR, npm, etc.).

## Usage

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Copy `terraform.tfvars.example` to `terraform.tfvars` to customize (optional).

## Outputs

| Output      | Description                    |
|------------|--------------------------------|
| `app_url`  | HTTP URL to access the app     |
| `alb_dns_name` | ALB DNS name (for CNAME)   |

## Health checks

The ALB targets instances on port 3000. If your NestJS app doesn't return 200 on `/`, set `health_check_path = "/health"` in `terraform.tfvars` and add a health endpoint to your app.

## Deployment note

The infrastructure now uses multiple EC2 instances behind a load balancer. The GitHub Actions deploy job (SCP to a single host) will need to be updated for this architecture. Common approaches:

- **AMI-based**: Bake the app into a custom AMI and update the launch template
- **CodeDeploy**: Use AWS CodeDeploy for rolling deployments
- **SSH to each instance**: Fetch ASG instance IPs and deploy to each (less ideal for scaling)
