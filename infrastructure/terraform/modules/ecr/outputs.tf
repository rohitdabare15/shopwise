output "repository_urls" {
  description = "Map of repository name to full ECR URL"
  value       = { for k, v in aws_ecr_repository.main : k => v.repository_url }
}

output "registry_id" {
  description = "ECR registry ID (same as AWS account ID)"
  value       = values(aws_ecr_repository.main)[0].registry_id
}

output "frontend_url" {
  value = aws_ecr_repository.main["frontend"].repository_url
}

output "backend_url" {
  value = aws_ecr_repository.main["backend"].repository_url
}
