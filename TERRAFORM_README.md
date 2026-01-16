# DevSecOps Terraform Configuration

This Terraform configuration provisions AWS infrastructure for the DevSecOps project.

## Files

- **main.tf** - Main infrastructure definitions (EC2 instance and security group)
- **variables.tf** - Input variables
- **outputs.tf** - Output values
- **user_data.sh** - EC2 initialization script

## Security Note

⚠️ **INTENTIONAL VULNERABILITY**: The security group allows SSH access from anywhere (0.0.0.0/0). This is intentionally configured for security scanner testing purposes.

## Prerequisites

1. AWS Account with appropriate credentials configured
2. Terraform >= 1.0
3. EC2 Key Pair created in your AWS region

## Usage

### Initialize Terraform

```bash
terraform init
```

### Plan Deployment

```bash
terraform plan -var="key_pair_name=your-key-pair-name"
```

### Apply Configuration

```bash
terraform apply -var="key_pair_name=your-key-pair-name"
```

### Destroy Resources

```bash
terraform destroy
```

## Variables

- `aws_region` - AWS region (default: us-east-1)
- `vpc_id` - VPC ID (optional, uses default VPC if not specified)
- `instance_type` - EC2 instance type (default: t3.micro)
- `key_pair_name` - EC2 Key Pair name (required)
- `environment` - Environment name (default: development)

## Outputs

- `instance_id` - EC2 instance ID
- `instance_public_ip` - Public IP address
- `instance_private_ip` - Private IP address
- `security_group_id` - Security group ID
- `ssh_connection_string` - SSH connection command
