resource "random_password" "mysql_root" {
  length           = 32
  special          = true
  override_special = "#%+-_="
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "mysql_app" {
  length           = 32
  special          = true
  override_special = "#%+-_="
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "rabbitmq" {
  length           = 32
  special          = true
  override_special = "#%+-_="
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "aws_kms_key" "secrets" {
  description             = "Customer-managed key for RoboShop SSM parameters"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_ssm_parameter" "mysql_root_password" {
  name        = "${local.ssm_prefix}/mysql/root_password"
  description = "MySQL root password. Valid for localhost only."
  type        = "SecureString"
  key_id      = aws_kms_key.secrets.arn
  value       = random_password.mysql_root.result
  tags        = var.tags
}

resource "aws_ssm_parameter" "mysql_app_user" {
  name        = "${local.ssm_prefix}/mysql/app_user"
  description = "MySQL application username for the shipping service."
  type        = "SecureString"
  key_id      = aws_kms_key.secrets.arn
  value       = var.mysql_app_user
  tags        = var.tags
}

resource "aws_ssm_parameter" "mysql_app_password" {
  name        = "${local.ssm_prefix}/mysql/app_password"
  description = "MySQL application password for the shipping service."
  type        = "SecureString"
  key_id      = aws_kms_key.secrets.arn
  value       = random_password.mysql_app.result
  tags        = var.tags
}

resource "aws_ssm_parameter" "mysql_app_host" {
  name        = "${local.ssm_prefix}/mysql/app_host"
  description = "MySQL host pattern for the shipping account, derived from the app subnet."
  type        = "SecureString"
  key_id      = aws_kms_key.secrets.arn
  value       = local.mysql_app_host
  tags        = var.tags
}

resource "aws_ssm_parameter" "rabbitmq_user" {
  name        = "${local.ssm_prefix}/rabbitmq/user"
  description = "RabbitMQ application username."
  type        = "SecureString"
  key_id      = aws_kms_key.secrets.arn
  value       = var.rabbitmq_user
  tags        = var.tags
}

resource "aws_ssm_parameter" "rabbitmq_password" {
  name        = "${local.ssm_prefix}/rabbitmq/password"
  description = "RabbitMQ application password. The guest account is not created."
  type        = "SecureString"
  key_id      = aws_kms_key.secrets.arn
  value       = random_password.rabbitmq.result
  tags        = var.tags
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-${var.environment}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ssm_read" {
  statement {
    sid    = "ReadRoboshopParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.mysql_root_password.arn,
      aws_ssm_parameter.mysql_app_user.arn,
      aws_ssm_parameter.mysql_app_password.arn,
      aws_ssm_parameter.mysql_app_host.arn,
      aws_ssm_parameter.rabbitmq_user.arn,
      aws_ssm_parameter.rabbitmq_password.arn,
    ]
  }

  statement {
    sid       = "DecryptSsmSecureStrings"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.secrets.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ssm_read" {
  name   = "${var.project_name}-${var.environment}-ssm-read"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.ssm_read.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2"
  role = aws_iam_role.ec2.name
  tags = var.tags
}
