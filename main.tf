terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC for the application
resource "aws_vpc" "devsecops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "devsecops-vpc"
    Environment = var.environment
  }
}

# Public Subnet - Public IP assignment controlled at instance level
resource "aws_subnet" "devsecops_subnet" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false  # FIXED: Don't auto-assign public IPs

  tags = {
    Name        = "devsecops-subnet"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "devsecops_igw" {
  vpc_id = aws_vpc.devsecops_vpc.id

  tags = {
    Name        = "devsecops-igw"
    Environment = var.environment
  }
}

# Route Table
resource "aws_route_table" "devsecops_rt" {
  vpc_id = aws_vpc.devsecops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devsecops_igw.id
  }

  tags = {
    Name        = "devsecops-route-table"
    Environment = var.environment
  }
}

# Route Table Association
resource "aws_route_table_association" "devsecops_rta" {
  subnet_id      = aws_subnet.devsecops_subnet.id
  route_table_id = aws_route_table.devsecops_rt.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group - Hardened configuration
resource "aws_security_group" "devsecops_sg" {
  name        = "devsecops-secure-sg"
  description = "Hardened security group following security best practices"
  vpc_id      = aws_vpc.devsecops_vpc.id

  # SSH restricted to specific trusted IP (replace with your actual IP or VPN CIDR)
  ingress {
    description = "SSH from trusted IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]  # Restricted to specific IP
  }

  # Allow HTTP for the application
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS for the application
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Node.js application port 3000 (your app will still be accessible!)
  ingress {
    description = "Node.js app on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # FIXED: Egress restricted to VPC CIDR only (no public internet access)
  # For production, use NAT Gateway + VPC Endpoints for external access
  egress {
    description = "Allow all outbound within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR only - no public internet
  }

  tags = {
    Name        = "devsecops-secure-sg"
    Environment = var.environment
    Purpose     = "Production-ready security"
  }
}

# EC2 Instance - Hardened configuration
resource "aws_instance" "devsecops_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.devsecops_subnet.id
  vpc_security_group_ids = [aws_security_group.devsecops_sg.id]
  key_name               = var.key_pair_name
  associate_public_ip_address = true

  # FIXED: Require IMDSv2 tokens to prevent SSRF attacks
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Forces IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true  # FIXED: Enable encryption at rest

    tags = {
      Name = "devsecops-root-volume"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    docker_compose_url = "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64"
  }))

  tags = {
    Name        = "devsecops-app-server"
    Environment = var.environment
  }

  depends_on = [aws_security_group.devsecops_sg]
}

# Data source to get the latest Ubuntu AMI
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
