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
  description = "CIDR block for private application subnet"
  type        = string
  default     = "10.0.10.0/24"
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
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}

# Security Configuration
variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instances"
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

# Phase 2-3 Variables
variable "private_domain" {
  description = "Private domain name for service discovery"
  type        = string
  default     = "roboshop.internal"
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
  default     = "RoboShop@1"
}

variable "rabbitmq_user" {
  description = "RabbitMQ username"
  type        = string
  default     = "roboshop"
}

variable "rabbitmq_password" {
  description = "RabbitMQ password"
  type        = string
  sensitive   = true
  default     = "roboshop123"
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
