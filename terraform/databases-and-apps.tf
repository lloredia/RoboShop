# Database and application instances.
# Credentials are not placed in user data. Boot scripts read SecureString
# parameters created in secrets.tf.

# =================================
# DATABASE TIER
# =================================

module "mongodb" {
  source = "../modules/ec2-instance"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "mongodb"
  tier               = "database"
  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = var.db_instance_type
  key_name           = aws_key_pair.roboshop.key_name
  subnet_id          = module.vpc.private_db_subnet_id
  security_group_ids = [module.security_groups.mongodb_sg_id]

  user_data_script = local.mongodb_userdata
  root_volume_size = 30
  data_volume_size = 50

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags
}

module "mysql" {
  source = "../modules/ec2-instance"

  project_name         = var.project_name
  environment          = var.environment
  service_name         = "mysql"
  tier                 = "database"
  ami_id               = data.aws_ami.amazon_linux_2.id
  instance_type        = var.db_instance_type
  key_name             = aws_key_pair.roboshop.key_name
  subnet_id            = module.vpc.private_db_subnet_id
  security_group_ids   = [module.security_groups.mysql_sg_id]
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data_script = local.mysql_userdata
  root_volume_size = 30
  data_volume_size = 50

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags
}

module "redis" {
  source = "../modules/ec2-instance"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "redis"
  tier               = "database"
  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = "t3.micro"
  key_name           = aws_key_pair.roboshop.key_name
  subnet_id          = module.vpc.private_db_subnet_id
  security_group_ids = [module.security_groups.redis_sg_id]

  user_data_script = local.redis_userdata
  root_volume_size = 20

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags
}

module "rabbitmq" {
  source = "../modules/ec2-instance"

  project_name         = var.project_name
  environment          = var.environment
  service_name         = "rabbitmq"
  tier                 = "database"
  ami_id               = data.aws_ami.amazon_linux_2.id
  instance_type        = "t3.micro"
  key_name             = aws_key_pair.roboshop.key_name
  subnet_id            = module.vpc.private_db_subnet_id
  security_group_ids   = [module.security_groups.rabbitmq_sg_id]
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data_script = local.rabbitmq_userdata
  root_volume_size = 20

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags
}

# =================================
# APPLICATION TIER
# =================================

module "frontend" {
  source = "../modules/ec2-instance"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "frontend"
  tier               = "application"
  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = var.app_instance_type
  key_name           = aws_key_pair.roboshop.key_name
  subnet_id          = module.vpc.private_app_subnet_id
  security_group_ids = [module.security_groups.frontend_sg_id]

  user_data_script = local.frontend_userdata

  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  enable_cpu_alarm       = true

  tags = var.tags
}

module "catalogue" {
  source = "../modules/ec2-instance"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "catalogue"
  tier               = "application"
  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = var.app_instance_type
  key_name           = aws_key_pair.roboshop.key_name
  subnet_id          = module.vpc.private_app_subnet_id
  security_group_ids = [module.security_groups.catalogue_sg_id]

  user_data_script = local.catalogue_userdata

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags

  depends_on = [module.mongodb]
}

module "user" {
  source = "../modules/ec2-instance"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "user"
  tier               = "application"
  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = var.app_instance_type
  key_name           = aws_key_pair.roboshop.key_name
  subnet_id          = module.vpc.private_app_subnet_id
  security_group_ids = [module.security_groups.user_sg_id]

  user_data_script = local.user_userdata

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags

  depends_on = [module.mongodb, module.redis]
}

module "cart" {
  source = "../modules/ec2-instance"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "cart"
  tier               = "application"
  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = var.app_instance_type
  key_name           = aws_key_pair.roboshop.key_name
  subnet_id          = module.vpc.private_app_subnet_id
  security_group_ids = [module.security_groups.cart_sg_id]

  user_data_script = local.cart_userdata

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags

  depends_on = [module.redis, module.catalogue]
}

module "shipping" {
  source = "../modules/ec2-instance"

  project_name         = var.project_name
  environment          = var.environment
  service_name         = "shipping"
  tier                 = "application"
  ami_id               = data.aws_ami.amazon_linux_2.id
  instance_type        = var.shipping_instance_type
  key_name             = aws_key_pair.roboshop.key_name
  subnet_id            = module.vpc.private_app_subnet_id
  security_group_ids   = [module.security_groups.shipping_sg_id]
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data_script = local.shipping_userdata

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags

  depends_on = [module.mysql, module.cart]
}

module "payment" {
  source = "../modules/ec2-instance"

  project_name         = var.project_name
  environment          = var.environment
  service_name         = "payment"
  tier                 = "application"
  ami_id               = data.aws_ami.amazon_linux_2.id
  instance_type        = var.app_instance_type
  key_name             = aws_key_pair.roboshop.key_name
  subnet_id            = module.vpc.private_app_subnet_id
  security_group_ids   = [module.security_groups.payment_sg_id]
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data_script = local.payment_userdata

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags

  depends_on = [module.rabbitmq, module.user, module.cart]
}

module "dispatch" {
  source = "../modules/ec2-instance"

  project_name         = var.project_name
  environment          = var.environment
  service_name         = "dispatch"
  tier                 = "application"
  ami_id               = data.aws_ami.amazon_linux_2.id
  instance_type        = var.app_instance_type
  key_name             = aws_key_pair.roboshop.key_name
  subnet_id            = module.vpc.private_app_subnet_id
  security_group_ids   = [module.security_groups.dispatch_sg_id]
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data_script = local.dispatch_userdata

  enable_cloudwatch_logs = true
  enable_health_alarm    = true

  tags = var.tags

  depends_on = [module.rabbitmq]
}
