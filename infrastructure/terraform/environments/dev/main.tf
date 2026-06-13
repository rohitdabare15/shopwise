terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Pin to major version — prevents breaking changes
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
    AutoDestroy = "true"  # Reminder tag — this env should be destroyed after sessions
  }
}
