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

# Public Subnet - VULNERABLE: Auto-assigning public IPs
resource "aws_subnet" "devsecops_subnet" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true  # VULNERABLE: Exposes resources by default

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

# Security Group - VULNERABLE: Wide open configuration
resource "aws_security_group" "devsecops_sg" {
  name        = "devsecops-vulnerable-sg"
  description = "Vulnerable security group for testing purposes"
  vpc_id      = aws_vpc.devsecops_vpc.id

  # VULNERABLE: SSH open to the entire internet
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node.js app on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABLE: Unrestricted egress
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devsecops-vulnerable-sg"
    Environment = var.environment
  }
}

# EC2 Instance - VULNERABLE: Insecure configuration
resource "aws_instance" "devsecops_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.devsecops_subnet.id
  vpc_security_group_ids = [aws_security_group.devsecops_sg.id]
  key_name               = var.key_pair_name
  associate_public_ip_address = true

  # VULNERABLE: Insecure IMDS configuration (SSRF risk)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # VULNERABLE: Should be 'required'
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = false # VULNERABLE: No encryption at rest

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

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}