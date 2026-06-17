output "eks_cluster_role_arn" {
  description = "ARN of the EKS control plane IAM role — passed to EKS cluster resource"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role — passed to EKS node group resource"
  value       = aws_iam_role.eks_node.arn
}

output "eks_node_role_name" {
  description = "Name of the EKS node role — needed to attach additional policies"
  value       = aws_iam_role.eks_node.name
}

output "backend_pod_role_arn" {
  description = "ARN of the backend IRSA role"
  value       = aws_iam_role.app_backend.arn
}


output "jenkins_role_arn" {
  description = "ARN of the Jenkins IAM role"
  value       = aws_iam_role.jenkins.arn
}

output "jenkins_instance_profile_name" {
  description = "Instance profile name — attached to Jenkins EC2 instance"
  value       = aws_iam_instance_profile.jenkins.name
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS Enhanced Monitoring role — passed to RDS module"
  value       = aws_iam_role.rds_monitoring.arn
}
