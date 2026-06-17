variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "database_subnet_ids" {
  description = "Private DB subnet IDs — RDS goes here, not app subnets"
  type        = list(string)
}

variable "app_subnet_cidr_blocks" {
  description = "CIDR blocks of app subnets — only source allowed to reach RDS"
  type        = list(string)
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "shopwise"
}

variable "db_username" {
  description = "Master username — never use 'admin' or 'root' (AWS reserves them)"
  type        = string
  default     = "shopwise_admin"
}

variable "db_password_secret_arn" {
  description = "Secrets Manager ARN containing the DB password"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "18.1"
}

variable "instance_class" {
  description = "RDS instance size"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max storage for autoscaling — RDS grows up to this automatically"
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Enable Multi-AZ standby. false for dev (cost), true for prod (HA)"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Days to keep automated backups. 0 disables backups (dev only)"
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Prevent accidental deletion. Always true in prod."
  type        = bool
  default     = false
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for RDS Enhanced Monitoring — from IAM module"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
