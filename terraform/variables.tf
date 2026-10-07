# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "roboshop"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_app_subnet_cidr" {
  description = "CIDR block for private application subnet. The shipping MySQL account is limited to this range."
  type        = string
  default     = "10.0.10.0/24"

  validation {
    condition     = can(cidrhost(var.private_app_subnet_cidr, 0))
    error_message = "private_app_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "private_db_subnet_cidr" {
  description = "CIDR block for private database subnet"
  type        = string
  default     = "10.0.20.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "us-east-1a"
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs. Off by default because CloudWatch ingestion is a lab cost."
  type        = bool
  default     = false
}

# Security Configuration
variable "admin_cidr" {
  description = "CIDR blocks allowed to SSH to the bastion. Use your own /32. 0.0.0.0/0 is rejected."
  type        = list(string)

  validation {
    condition = (
      length(var.admin_cidr) > 0 &&
      !contains(var.admin_cidr, "0.0.0.0/0") &&
      !contains(var.admin_cidr, "::/0")
    )
    error_message = "admin_cidr must list at least one CIDR and must not be open to the whole internet."
  }
}

variable "ssh_public_key" {
  description = "SSH public key material for the EC2 key pair"
  type        = string
}

# Instance Configuration
variable "app_instance_type" {
  description = "Instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database servers"
  type        = string
  default     = "t3.small"
}

variable "shipping_instance_type" {
  description = "Instance type for the shipping service. Maven builds need more memory than the other apps."
  type        = string
  default     = "t3.small"
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "RoboShop"
    ManagedBy   = "Terraform"
    Environment = "Development"
  }
}

variable "private_domain" {
  description = "Private domain name for service discovery"
  type        = string
  default     = "roboshop.internal"
}

variable "mysql_app_user" {
  description = "Least-privilege MySQL account used by the shipping service. This is a username, not a password."
  type        = string
  default     = "shipping"
}

variable "rabbitmq_user" {
  description = "RabbitMQ application username. The password is generated and stored in SSM."
  type        = string
  default     = "roboshop"
}

variable "frontend_artifact_url" {
  description = "Frontend artifact URL"
  type        = string
  default     = "https://roboshop-artifacts.s3.amazonaws.com/frontend.zip"
}

variable "catalogue_artifact_url" {
  description = "Catalogue service artifact URL"
  type        = string
  default     = "https://roboshop-artifacts.s3.amazonaws.com/catalogue.zip"
}

variable "user_artifact_url" {
  description = "User service artifact URL"
  type        = string
  default     = "https://roboshop-artifacts.s3.amazonaws.com/user.zip"
}

variable "cart_artifact_url" {
  description = "Cart service artifact URL"
  type        = string
  default     = "https://roboshop-artifacts.s3.amazonaws.com/cart.zip"
}

variable "shipping_artifact_url" {
  description = "Shipping service artifact URL"
  type        = string
  default     = "https://roboshop-artifacts.s3.amazonaws.com/shipping.zip"
}

variable "payment_artifact_url" {
  description = "Payment service artifact URL"
  type        = string
  default     = "https://roboshop-artifacts.s3.amazonaws.com/payment.zip"
}

variable "dispatch_artifact_url" {
  description = "Dispatch service artifact URL"
  type        = string
  default     = "https://roboshop-artifacts.s3.amazonaws.com/dispatch.zip"
}

variable "catalogue_schema_url" {
  description = "Catalogue MongoDB schema URL"
  type        = string
  default     = "https://raw.githubusercontent.com/roboshop-devops-project/mongodb/main/catalogue.js"
}

variable "user_schema_url" {
  description = "User MongoDB schema URL"
  type        = string
  default     = "https://raw.githubusercontent.com/roboshop-devops-project/mongodb/main/user.js"
}

variable "shipping_schema_url" {
  description = "Shipping MySQL schema URL. GRANT statements in this file are stripped before load."
  type        = string
  default     = "https://raw.githubusercontent.com/roboshop-devops-project/mysql/main/shipping.sql"
}
