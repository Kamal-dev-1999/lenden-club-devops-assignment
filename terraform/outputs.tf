output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.devsecops_app.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.devsecops_app.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.devsecops_app.private_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.devsecops_sg.id
}

output "security_group_name" {
  description = "Security Group name"
  value       = aws_security_group.devsecops_sg.name
}

output "ssh_connection_string" {
  description = "SSH connection string to the instance"
  value       = "ssh -i /path/to/key.pem ubuntu@${aws_instance.devsecops_app.public_ip}"
}
