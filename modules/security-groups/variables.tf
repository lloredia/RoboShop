variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR blocks allowed to SSH to the bastion. Must not include 0.0.0.0/0."
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

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
