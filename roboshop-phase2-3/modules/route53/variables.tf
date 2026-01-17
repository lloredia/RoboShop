variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for private hosted zone"
  type        = string
}

variable "domain_name" {
  description = "Domain name for private hosted zone (e.g., roboshop.internal)"
  type        = string
  default     = "roboshop.internal"
}

variable "ttl" {
  description = "TTL for DNS records"
  type        = number
  default     = 300
}

variable "service_records" {
  description = "Map of service names to IP addresses for A records"
  type        = map(string)
  default     = {}
  # Example:
  # {
  #   "mongodb" = "10.0.20.10"
  #   "mysql"   = "10.0.20.11"
  # }
}

variable "cname_records" {
  description = "Map of aliases to target domains for CNAME records"
  type        = map(string)
  default     = {}
  # Example:
  # {
  #   "db"    = "mongodb.roboshop.internal"
  #   "cache" = "redis.roboshop.internal"
  # }
}

variable "health_check_configs" {
  description = "Map of health check configurations"
  type = map(object({
    ip_address        = string
    port              = number
    type              = string
    resource_path     = optional(string)
    failure_threshold = optional(number)
    request_interval  = optional(number)
  }))
  default = {}
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
