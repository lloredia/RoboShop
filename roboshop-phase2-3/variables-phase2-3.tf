# Additional variables for Phase 2 & 3 deployment
# Add these to your existing variables.tf

# Private DNS Configuration
variable "private_domain" {
  description = "Private domain name for service discovery"
  type        = string
  default     = "roboshop.internal"
}

# Database Passwords
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

# Application Artifact URLs
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

# Schema URLs (for database initialization)
variable "catalogue_schema_url" {
  description = "Catalogue MongoDB schema URL"
  type        = string
  default     = "https://raw.githubusercontent.com/roboshop-devops-project/catalogue/main/schema/catalogue.js"
}

variable "user_schema_url" {
  description = "User MongoDB schema URL"
  type        = string
  default     = "https://raw.githubusercontent.com/roboshop-devops-project/user/main/schema/user.js"
}

variable "shipping_schema_url" {
  description = "Shipping MySQL schema URL"
  type        = string
  default     = "https://raw.githubusercontent.com/roboshop-devops-project/shipping/main/schema/shipping.sql"
}
