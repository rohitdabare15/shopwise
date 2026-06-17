output "db_endpoint" {
  description = "RDS endpoint — used by backend app to connect"
  value       = aws_db_instance.main.endpoint
}

output "db_host" {
  description = "RDS hostname only (no port)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_security_group_id" {
  description = "Security group ID — reference when adding more ingress rules"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}
