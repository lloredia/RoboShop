# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

output "private_app_subnet_id" {
  description = "Private application subnet ID"
  value       = module.vpc.private_app_subnet_id
}

output "private_db_subnet_id" {
  description = "Private database subnet ID"
  value       = module.vpc.private_db_subnet_id
}

# Bastion Outputs
output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_eip.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Bastion instance ID"
  value       = aws_instance.bastion.id
}

# SSH Connection Info
output "ssh_connection_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i ~/.ssh/roboshop ec2-user@${aws_eip.bastion.public_ip}"
}

# Security Group Outputs
output "security_groups" {
  description = "All security group IDs"
  value = {
    bastion   = module.security_groups.bastion_sg_id
    alb       = module.security_groups.alb_sg_id
    frontend  = module.security_groups.frontend_sg_id
    catalogue = module.security_groups.catalogue_sg_id
    user      = module.security_groups.user_sg_id
    cart      = module.security_groups.cart_sg_id
    shipping  = module.security_groups.shipping_sg_id
    payment   = module.security_groups.payment_sg_id
    dispatch  = module.security_groups.dispatch_sg_id
    mongodb   = module.security_groups.mongodb_sg_id
    mysql     = module.security_groups.mysql_sg_id
    redis     = module.security_groups.redis_sg_id
    rabbitmq  = module.security_groups.rabbitmq_sg_id
  }
}
