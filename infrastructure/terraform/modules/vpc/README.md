'EOF'
# VPC Module

Provisions a production-grade 3-tier VPC with public, private-app, and private-db
subnets across multiple Availability Zones.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name             = "shopwise"
  environment              = "dev"
  vpc_cidr                 = "10.0.0.0/16"
  availability_zones       = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  private_db_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
  single_nat_gateway       = true
}
```

## Resources Created

| Resource | Count | Notes |
|---|---|---|
| VPC | 1 | DNS hostnames enabled |
| Internet Gateway | 1 | Attached to VPC |
| Public Subnets | 1 per AZ | Auto-assign public IP |
| Private App Subnets | 1 per AZ | EKS nodes |
| Private DB Subnets | 1 per AZ | RDS, no internet route |
| NAT Gateway | 1 or 1 per AZ | Controlled by `single_nat_gateway` |
| Elastic IPs | 1 or 1 per AZ | For NAT Gateways |
| Route Tables | 1 public + 2 per AZ | |
| VPC Flow Logs | 1 | 30-day retention |

## Cost (us-east-1)

| Config | $/month |
|---|---|
| single_nat_gateway = true | ~$33 |
| single_nat_gateway = false (3 AZs) | ~$99 |

## Outputs

- `vpc_id` — used by every other module
- `public_subnet_ids` — used by ALB module
- `private_app_subnet_ids` — used by EKS module
- `private_db_subnet_ids` — used by RDS module
- `nat_gateway_public_ips` — whitelist in external services
EOF
