# Required Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the service (mongodb, frontend, catalogue, etc.)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

# Optional Variables
variable "tier" {
  description = "Tier of the service (database, application, frontend)"
  type        = string
  default     = "application"
}

variable "user_data_script" {
  description = "User data script to execute on first boot"
  type        = string
  default     = ""
}

variable "user_data_replace_on_change" {
  description = "Replace instance if user data changes"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

# Volume Configuration
variable "root_volume_type" {
  description = "Root volume type (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "data_volume_type" {
  description = "Data volume type (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "data_volume_size" {
  description = "Data volume size in GB (0 to disable)"
  type        = number
  default     = 0
}

variable "enable_encryption" {
  description = "Enable EBS encryption"
  type        = bool
  default     = true
}

# IAM Configuration
variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
  default     = ""
}

# CloudWatch Configuration
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch log group"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Alarms Configuration
variable "enable_health_alarm" {
  description = "Enable health check alarm"
  type        = bool
  default     = false
}

variable "enable_cpu_alarm" {
  description = "Enable CPU utilization alarm"
  type        = bool
  default     = false
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for alarm (percentage)"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

# Elastic IP Configuration
variable "allocate_eip" {
  description = "Allocate Elastic IP"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
