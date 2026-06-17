output "cluster_name" {
  description = "EKS cluster name — used in kubectl commands and IAM policies"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "API server endpoint — kubectl connects here"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate — used to verify the API server"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  value = aws_eks_cluster.main.version
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — fed back into IAM module for IRSA roles"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL without https:// — used in IAM trust policies"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

output "node_group_asg_name" {
  description = "Auto Scaling Group name — used by Cluster Autoscaler"
  value       = try(aws_eks_node_group.main.resources[0].autoscaling_groups[0].name, "")
}

output "kms_key_arn" {
  description = "KMS key ARN used for secrets encryption"
  value       = aws_kms_key.eks.arn
}
