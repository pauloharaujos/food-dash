# terraform/network.tf
# VPC, subnets, internet gateway, and routing

resource "aws_vpc" "fooddash_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.fooddash_vpc.id

  tags = merge(local.common_tags, { Name = "${var.project_name}-igw" })
}

resource "aws_subnet" "public_subnet" {
  for_each = {
    "a" = { az = "us-east-1a", cidr = "10.0.1.0/24" }
    "b" = { az = "us-east-1b", cidr = "10.0.2.0/24" }
  }

  vpc_id                  = aws_vpc.fooddash_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-public-${each.key}" })
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fooddash_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}
