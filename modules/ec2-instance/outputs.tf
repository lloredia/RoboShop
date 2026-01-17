output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "Instance ARN"
  value       = aws_instance.main.arn
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.main.private_ip
}

output "private_dns" {
  description = "Private DNS name"
  value       = aws_instance.main.private_dns
}

output "public_ip" {
  description = "Public IP address (if allocated)"
  value       = var.allocate_eip ? aws_eip.main[0].public_ip : aws_instance.main.public_ip
}

output "availability_zone" {
  description = "Availability zone"
  value       = aws_instance.main.availability_zone
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_instance.main.subnet_id
}

output "security_group_ids" {
  description = "Security group IDs"
  value       = aws_instance.main.vpc_security_group_ids
}

output "key_name" {
  description = "SSH key pair name"
  value       = aws_instance.main.key_name
}

output "instance_state" {
  description = "Instance state"
  value       = aws_instance.main.instance_state
}

output "tags" {
  description = "Instance tags"
  value       = aws_instance.main.tags
}
