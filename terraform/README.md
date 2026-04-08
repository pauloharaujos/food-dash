# FoodDash Terraform Infrastructure

## Architecture

- **VPC** with 2 public subnets (multi-AZ: us-east-1a, us-east-1b)
- **Application Load Balancer (ALB)** distributing traffic across instances
- **Auto Scaling Group (ASG)** with 2–4 EC2 instances (configurable)
- **Security groups** with defense in depth: instances accept traffic only from ALB on port 3000

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
