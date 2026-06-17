variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_version" {
  description = "Kubernetes version. Check AWS docs for latest supported version."
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID from the VPC module output"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private app subnet IDs — control plane ENIs and nodes go here"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane — from IAM module output"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for worker nodes — from IAM module output"
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum nodes — cluster autoscaler won't go below this"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum nodes — cluster autoscaler won't go above this"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Root EBS volume size in GB for each worker node"
  type        = number
  default     = 20
}

variable "cluster_log_types" {
  description = "EKS control plane log types to send to CloudWatch"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
