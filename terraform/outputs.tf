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
  value       = "ssh -i ~/.ssh/roboshop-key ec2-user@${aws_eip.bastion.public_ip}"
}

output "route53_zone_id" {
  description = "Private hosted zone ID"
  value       = module.route53.zone_id
}

output "instance_private_ips" {
  description = "Private IP of each service instance"
  value = {
    mongodb   = module.mongodb.private_ip
    mysql     = module.mysql.private_ip
    redis     = module.redis.private_ip
    rabbitmq  = module.rabbitmq.private_ip
    frontend  = module.frontend.private_ip
    catalogue = module.catalogue.private_ip
    user      = module.user.private_ip
    cart      = module.cart.private_ip
    shipping  = module.shipping.private_ip
    payment   = module.payment.private_ip
    dispatch  = module.dispatch.private_ip
  }
}

output "ssm_parameter_names" {
  description = "SSM parameter names for generated credentials. Values are not outputs."
  value = {
    mysql_root_password = aws_ssm_parameter.mysql_root_password.name
    mysql_app_user      = aws_ssm_parameter.mysql_app_user.name
    mysql_app_password  = aws_ssm_parameter.mysql_app_password.name
    mysql_app_host      = aws_ssm_parameter.mysql_app_host.name
    rabbitmq_user       = aws_ssm_parameter.rabbitmq_user.name
    rabbitmq_password   = aws_ssm_parameter.rabbitmq_password.name
  }
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
