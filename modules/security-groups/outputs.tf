output "bastion_sg_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.bastion.id
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "frontend_sg_id" {
  description = "Frontend security group ID"
  value       = aws_security_group.frontend.id
}

output "catalogue_sg_id" {
  description = "Catalogue security group ID"
  value       = aws_security_group.catalogue.id
}

output "user_sg_id" {
  description = "User security group ID"
  value       = aws_security_group.user.id
}

output "cart_sg_id" {
  description = "Cart security group ID"
  value       = aws_security_group.cart.id
}

output "shipping_sg_id" {
  description = "Shipping security group ID"
  value       = aws_security_group.shipping.id
}

output "payment_sg_id" {
  description = "Payment security group ID"
  value       = aws_security_group.payment.id
}

output "dispatch_sg_id" {
  description = "Dispatch security group ID"
  value       = aws_security_group.dispatch.id
}

output "mongodb_sg_id" {
  description = "MongoDB security group ID"
  value       = aws_security_group.mongodb.id
}

output "mysql_sg_id" {
  description = "MySQL security group ID"
  value       = aws_security_group.mysql.id
}

output "redis_sg_id" {
  description = "Redis security group ID"
  value       = aws_security_group.redis.id
}

output "rabbitmq_sg_id" {
  description = "RabbitMQ security group ID"
  value       = aws_security_group.rabbitmq.id
}
