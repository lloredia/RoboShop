# Route53 Private Hosted Zone
module "route53" {
  source = "../modules/route53"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  domain_name  = var.private_domain

  service_records = {
    mongodb   = module.mongodb.private_ip
    mysql     = module.mysql.private_ip
    redis     = module.redis.private_ip
    rabbitmq  = module.rabbitmq.private_ip
    frontend  = module.frontend.private_ip
    catalogue = module.catalogue.private_ip
    user      = module.user.private_ip
    cart      = module.cart.private_ip
  }

  tags = var.tags
}
