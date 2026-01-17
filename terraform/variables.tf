variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

# SECURITY: Variable for allowed SSH CIDR block
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance (e.g., your office IP/32)"
  type        = string
  default     = "10.0.0.0/8"  # Default to private network - override in production
}
