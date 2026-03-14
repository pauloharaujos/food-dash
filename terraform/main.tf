# terraform/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. The Network
resource "aws_vpc" "fooddash_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "fooddash-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.fooddash_vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.fooddash_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fooddash_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 2. Security Group (The Firewall)
resource "aws_security_group" "backend_sg" {
  name   = "fooddash-backend-sg"
  vpc_id = aws_vpc.fooddash_vpc.id

  # SSH access (for you to jump in)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In a real job, you'd use your specific IP
  }

  # NestJS port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Standard Outbound (Allow the server to download Node.js, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. The EC2 Instance
resource "aws_instance" "backend_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  # This links to your script
  user_data = file("scripts/setup.sh")

  tags = { Name = "FoodDash-Backend-Dev" }
}

# 4. Output the IP
output "server_ip" {
  value = aws_instance.backend_server.public_ip
}