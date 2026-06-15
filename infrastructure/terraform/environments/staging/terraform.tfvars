# infrastructure/terraform/environments/staging/terraform.tfvars
# NOT DEPLOYED — demonstrates how staging would differ from dev

project_name = "shopwise"
environment  = "staging"
aws_region   = "us-east-1"

# Staging uses a different CIDR block — no overlap with dev (10.0.x.x)
vpc_cidr = "10.1.0.0/16"

availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_app_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
private_db_subnet_cidrs  = ["10.1.20.0/24", "10.1.21.0/24", "10.1.22.0/24"]

# Staging: still single NAT GW to save cost, but production should use one per AZ
single_nat_gateway = true
