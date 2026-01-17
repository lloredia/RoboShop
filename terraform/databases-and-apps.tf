# RoboShop Phase 2 & 3: Database and Application Deployment

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
  
  enable_cloudwatch_logs = false
  enable_health_alarm    = false
  
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
  
  user_data_script = file("${path.module}/../user-data/mysql.sh")
  root_volume_size = 30
  data_volume_size = 50
  
  enable_cloudwatch_logs = false
  enable_health_alarm    = false
  
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
  
  enable_cloudwatch_logs = false
  enable_health_alarm    = false
  
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
  
  user_data_script = file("${path.module}/../user-data/rabbitmq.sh")
  root_volume_size = 20
  
  enable_cloudwatch_logs = false
  enable_health_alarm    = false
  
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
  
  user_data_script = file("${path.module}/../user-data/frontend.sh")
  
  enable_cloudwatch_logs = false
  enable_health_alarm    = false
  enable_cpu_alarm       = false
  
  tags = var.tags
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
  
  user_data_script = <<-EOF
    #!/bin/bash
    export SERVICE_NAME="catalogue"
    export SERVICE_PORT="8080"
    export SERVICE_URL="${var.catalogue_artifact_url}"
    curl -o /tmp/nodejs-service.sh https://raw.githubusercontent.com/lloredia/RoboShop/main/user-data/nodejs-service.sh || \
    cp ${path.module}/../user-data/nodejs-service.sh /tmp/nodejs-service.sh
    chmod +x /tmp/nodejs-service.sh
    /tmp/nodejs-service.sh
  EOF
  
  enable_cloudwatch_logs = false
  enable_health_alarm    = false
  
  tags = var.tags
  
  depends_on = [module.mongodb]
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
  
  user_data_script = <<-EOF
    #!/bin/bash
    export SERVICE_NAME="user"
    export SERVICE_PORT="8080"
    export SERVICE_URL="${var.user_artifact_url}"
    cp ${path.module}/../user-data/nodejs-service.sh /tmp/nodejs-service.sh
    chmod +x /tmp/nodejs-service.sh
    /tmp/nodejs-service.sh
  EOF
  
  enable_cloudwatch_logs = false
  enable_health_alarm    = false
  
  tags = var.tags
  
  depends_on = [module.mongodb]
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
  
  user_data_script = <<-EOF
    #!/bin/bash
    export SERVICE_NAME="cart"
    export SERVICE_PORT="8080"
    export SERVICE_URL="${var.cart_artifact_url}"
    cp ${path.module}/../user-data/nodejs-service.sh /tmp/nodejs-service.sh
    chmod +x /tmp/nodejs-service.sh
    /tmp/nodejs-service.sh
  EOF
  
  enable_cloudwatch_logs = false
  enable_health_alarm    = false
  
  tags = var.tags
  
  depends_on = [module.redis]
}

# Route53 will be added after instances are created
# You can create it manually or in a second terraform apply
