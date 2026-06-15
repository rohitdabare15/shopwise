# infrastructure/terraform/environments/prod/terraform.tfvars
# NOT DEPLOYED — demonstrates production configuration

project_name = "shopwise"
environment  = "prod"
aws_region   = "us-east-1"

# Prod uses 10.2.x.x — clean separation from dev and staging
vpc_cidr = "10.2.0.0/16"

availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs      = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_app_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
private_db_subnet_cidrs  = ["10.2.20.0/24", "10.2.21.0/24", "10.2.22.0/24"]

# Prod: one NAT Gateway per AZ — if one AZ fails, other AZs still have outbound internet
# This costs ~$96/month more than single NAT GW but prevents full outage
single_nat_gateway = false
