terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Pin to major version — prevents breaking changes
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Every resource created gets these tags automatically
  # No more forgetting to tag things
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "shopwise-team"
      CostCenter  = "shopwise-dev"
    }
  }
}

# ─── VPC Module ───────────────────────────────────────────────────────────────
# This calls our reusable VPC module and passes in dev-specific values.
# Staging and prod will call the same module with different values.

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs

  # Dev uses a single NAT Gateway to save ~$32/month
  single_nat_gateway = true

  tags = {
    Team        = "platform"
    AutoDestroy = "true" # Reminder tag — this env should be destroyed after sessions
  }
}
module "iam" {
  source = "../../modules/iam"

  project_name     = var.project_name
  environment      = var.environment
  aws_account_id   = data.aws_caller_identity.current.account_id
  aws_region       = var.aws_region
  eks_cluster_name = "${var.project_name}-${var.environment}"

  # OIDC values are empty until Phase 6 creates the EKS cluster
  # We'll run terraform apply again after Phase 6 to populate these
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_provider_url = module.eks.oidc_provider_url

  tags = {
    Team = "platform"
  }
}

module "eks" {
  source = "../../modules/eks"

  project_name = var.project_name
  environment  = var.environment

  # Pull subnet and VPC IDs directly from VPC module outputs
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_app_subnet_ids

  # Pull role ARNs from IAM module outputs
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  # Dev sizing — small and cheap
  cluster_version     = "1.31"
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3
  node_disk_size      = 20

  tags = {
    Team        = "platform"
    AutoDestroy = "true"
  }
}

module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment  = var.environment

  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.private_db_subnet_ids

  # Only EKS app nodes can reach RDS
  app_subnet_cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  db_name                = "shopwise"
  db_password_secret_arn = var.db_password_secret_arn
  monitoring_role_arn    = module.iam.rds_monitoring_role_arn

  # Dev settings — small and cheap
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  multi_az              = false
  backup_retention_days = 1
  deletion_protection   = false

  tags = {
    Team = "platform"
  }
}
# ── Feed OIDC values back into IAM module ──────────────────────
# Now that EKS exists, update the IAM module with the OIDC
# provider details so the backend IRSA role gets created.
# Terraform handles the dependency ordering automatically.
# Data source — reads your current AWS account ID automatically
# Means you never hardcode 617162869021 in Terraform code
data "aws_caller_identity" "current" {}
