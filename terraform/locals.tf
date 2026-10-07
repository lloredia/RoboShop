locals {
  ssm_prefix = "/${var.project_name}/${var.environment}"

  # MySQL account hosts cannot take a CIDR. 10.0.10.0/24 becomes 10.0.10.%
  mysql_app_host = format(
    "%s.%%",
    join(".", slice(split(".", cidrhost(var.private_app_subnet_cidr, 0)), 0, 3))
  )
}

locals {
  bootstrap_header = <<-EOT
    #!/bin/bash
    set -euo pipefail
    mkdir -p /etc/roboshop
    cat > /etc/roboshop/bootstrap.env <<'EOF'
    SSM_PREFIX=${local.ssm_prefix}
    AWS_DEFAULT_REGION=${var.aws_region}
    MYSQL_APP_HOST_PATTERN=${local.mysql_app_host}
    PRIVATE_DOMAIN=${var.private_domain}
    MYSQL_APP_USER=${var.mysql_app_user}
    RABBITMQ_APP_USER=${var.rabbitmq_user}
    FRONTEND_URL=${var.frontend_artifact_url}
    CATALOGUE_SCHEMA_URL=${var.catalogue_schema_url}
    USER_SCHEMA_URL=${var.user_schema_url}
    SHIPPING_SCHEMA_URL=${var.shipping_schema_url}
    SHIPPING_URL=${var.shipping_artifact_url}
    PAYMENT_URL=${var.payment_artifact_url}
    DISPATCH_URL=${var.dispatch_artifact_url}
    EOF
    chmod 0644 /etc/roboshop/bootstrap.env
    set -a
    # shellcheck disable=SC1091
    . /etc/roboshop/bootstrap.env
    set +a
  EOT

  mongodb_userdata  = "${local.bootstrap_header}\n${file("${path.module}/../user-data/mongodb.sh")}"
  mysql_userdata    = "${local.bootstrap_header}\n${file("${path.module}/../user-data/mysql.sh")}"
  redis_userdata    = "${local.bootstrap_header}\n${file("${path.module}/../user-data/redis.sh")}"
  rabbitmq_userdata = "${local.bootstrap_header}\n${file("${path.module}/../user-data/rabbitmq.sh")}"
  frontend_userdata = "${local.bootstrap_header}\n${file("${path.module}/../user-data/frontend.sh")}"
  shipping_userdata = "${local.bootstrap_header}\n${file("${path.module}/../user-data/shipping.sh")}"
  payment_userdata  = "${local.bootstrap_header}\n${file("${path.module}/../user-data/payment.sh")}"
  dispatch_userdata = "${local.bootstrap_header}\n${file("${path.module}/../user-data/dispatch.sh")}"

  catalogue_userdata = join("\n", [
    local.bootstrap_header,
    "export SERVICE_NAME=catalogue",
    "export SERVICE_PORT=8080",
    "export SERVICE_URL='${var.catalogue_artifact_url}'",
    "cat > /etc/roboshop/service.env <<'EOF'",
    "MONGO=true",
    "MONGO_URL=mongodb://mongodb.${var.private_domain}:27017/catalogue",
    "EOF",
    file("${path.module}/../user-data/nodejs-service.sh"),
  ])

  user_userdata = join("\n", [
    local.bootstrap_header,
    "export SERVICE_NAME=user",
    "export SERVICE_PORT=8080",
    "export SERVICE_URL='${var.user_artifact_url}'",
    "cat > /etc/roboshop/service.env <<'EOF'",
    "MONGO=true",
    "REDIS_HOST=redis.${var.private_domain}",
    "MONGO_URL=mongodb://mongodb.${var.private_domain}:27017/users",
    "EOF",
    file("${path.module}/../user-data/nodejs-service.sh"),
  ])

  cart_userdata = join("\n", [
    local.bootstrap_header,
    "export SERVICE_NAME=cart",
    "export SERVICE_PORT=8080",
    "export SERVICE_URL='${var.cart_artifact_url}'",
    "cat > /etc/roboshop/service.env <<'EOF'",
    "REDIS_HOST=redis.${var.private_domain}",
    "CATALOGUE_HOST=catalogue.${var.private_domain}",
    "CATALOGUE_PORT=8080",
    "EOF",
    file("${path.module}/../user-data/nodejs-service.sh"),
  ])
}
