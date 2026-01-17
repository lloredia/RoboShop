# RoboShop Phase 2 & 3: Database and Application Deployment
# Add this to your existing main.tf or use as a separate deployment

# Data source for AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Route53 Private Hosted Zone for Service Discovery
module "route53" {
  source = "../modules/route53"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  domain_name  = var.private_domain

  service_records = {
    mongodb  = module.mongodb.private_ip
    mysql    = module.mysql.private_ip
    redis    = module.redis.private_ip
    rabbitmq = module.rabbitmq.private_ip
    frontend = module.frontend.private_ip
    catalogue = module.catalogue.private_ip
    user     = module.user.private_ip
    cart     = module.cart.private_ip
  }

  tags = var.tags
}

# =================================
# DATABASE TIER
# =================================

# MongoDB
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
  
  user_data_script   = file("${path.module}/../user-data/mongodb.sh")
  root_volume_size   = 30
  data_volume_size   = 50
  
  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  
  tags = var.tags
}

# MySQL
module "mysql" {
  source = "../modules/ec2-instance"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "mysql"
  tier               = "database"
  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = var.db_instance_type
  key_name           = aws_key_pair.roboshop.key_name
  subnet_id          = module.vpc.private_db_subnet_id
  security_group_ids = [module.security_groups.mysql_sg_id]
  
  user_data_script = templatefile("${path.module}/../user-data/mysql.sh", {
    MYSQL_ROOT_PASSWORD = var.mysql_root_password
  })
  root_volume_size = 30
  data_volume_size = 50
  
  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  
  tags = var.tags
}

# Redis
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
  
  user_data_script   = file("${path.module}/../user-data/redis.sh")
  root_volume_size   = 20
  
  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  
  tags = var.tags
}

# RabbitMQ
module "rabbitmq" {
  source = "../modules/ec2-instance"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "rabbitmq"
  tier               = "database"
  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = "t3.micro"
  key_name           = aws_key_pair.roboshop.key_name
  subnet_id          = module.vpc.private_db_subnet_id
  security_group_ids = [module.security_groups.rabbitmq_sg_id]
  
  user_data_script = templatefile("${path.module}/../user-data/rabbitmq.sh", {
    RABBITMQ_USER     = var.rabbitmq_user
    RABBITMQ_PASSWORD = var.rabbitmq_password
  })
  root_volume_size = 20
  
  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  
  tags = var.tags
}

# =================================
# APPLICATION TIER
# =================================

# Frontend (Nginx)
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
  
  user_data_script = templatefile("${path.module}/../user-data/frontend.sh", {
    FRONTEND_URL = var.frontend_artifact_url
  })
  
  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  enable_cpu_alarm       = true
  
  tags = var.tags
  
  depends_on = [module.route53]
}

# Catalogue Service (Node.js)
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
  
  user_data_script = templatefile("${path.module}/../user-data/nodejs-service.sh", {
    SERVICE_NAME = "catalogue"
    SERVICE_PORT = "8080"
    SERVICE_URL  = var.catalogue_artifact_url
  })
  
  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  
  tags = var.tags
  
  depends_on = [module.mongodb, module.route53]
}

# User Service (Node.js)
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
  
  user_data_script = templatefile("${path.module}/../user-data/nodejs-service.sh", {
    SERVICE_NAME = "user"
    SERVICE_PORT = "8080"
    SERVICE_URL  = var.user_artifact_url
  })
  
  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  
  tags = var.tags
  
  depends_on = [module.mongodb, module.route53]
}

# Cart Service (Node.js)
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
  
  user_data_script = templatefile("${path.module}/../user-data/nodejs-service.sh", {
    SERVICE_NAME = "cart"
    SERVICE_PORT = "8080"
    SERVICE_URL  = var.cart_artifact_url
  })
  
  enable_cloudwatch_logs = true
  enable_health_alarm    = true
  
  tags = var.tags
  
  depends_on = [module.redis, module.route53]
}

# NOTE: Shipping (Java), Payment (Python), and Dispatch (Go) services
# would follow similar patterns with their respective installation scripts
