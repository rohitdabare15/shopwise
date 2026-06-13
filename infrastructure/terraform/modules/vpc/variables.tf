# Every value the module accepts as input.
# The environment (dev/staging/prod) passes these in when calling the module.

variable "project_name" {
  description = "Name prefix for all resources — keeps naming consistent"
  type        = string
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the entire VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy into — must have at least 2 for HA"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 Availability Zones are required for high availability."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets — one per AZ"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app subnets (EKS nodes) — one per AZ"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets (RDS) — one per AZ"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use one NAT Gateway for all AZs (cheaper for dev). False = one per AZ (prod)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource — required for cost tracking"
  type        = map(string)
  default     = {}
}
