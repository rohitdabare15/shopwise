# infrastructure/terraform/environments/dev/terraform.tfvars

project_name = "shopwise"
environment  = "dev"
aws_region   = "us-east-1"

vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
private_db_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
