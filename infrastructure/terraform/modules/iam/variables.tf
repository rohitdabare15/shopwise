variable "project_name" {
  description = "Project name prefix for all IAM resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID — used to scope IAM policy ARNs"
  type        = string
}

variable "aws_region" {
  description = "AWS region — used to scope IAM policy ARNs"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name — needed for node role trust policy"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN — enables IRSA (pod-level IAM roles)"
  type        = string
  default     = "" # Populated after EKS cluster exists in Phase 6
}

variable "eks_oidc_provider_url" {
  description = "EKS OIDC provider URL (without https://) — used in IRSA trust policies"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}
