output "vpc_id" {
  description = "VPC ID — needed when manually inspecting resources in the console"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.vpc.private_db_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Whitelist these IPs in any external service that needs to trust your VPC outbound traffic"
  value       = module.vpc.nat_gateway_public_ips
}
output "eks_cluster_role_arn" {
  value = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  value = module.iam.eks_node_role_arn
}

output "jenkins_instance_profile_name" {
  value = module.iam.jenkins_instance_profile_name
}

output "rds_monitoring_role_arn" {
  value = module.iam.rds_monitoring_role_arn
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "db_host" {
  value     = module.rds.db_host
  sensitive = true
}
