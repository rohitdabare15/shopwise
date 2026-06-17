locals {
  identifier = "${var.project_name}-${var.environment}-postgres"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "rds"
  })
}

# ═══════════════════════════════════════════════════════════════
# FETCH PASSWORD FROM SECRETS MANAGER
# ═══════════════════════════════════════════════════════════════
# Terraform reads the secret at plan time to pass to RDS.
# The password itself never appears in your .tf files.
# It WILL appear in state — which is why state encryption matters.

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}

locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_password.secret_string
  )
}

# ═══════════════════════════════════════════════════════════════
# SECURITY GROUP
# ═══════════════════════════════════════════════════════════════
# The most important security control for RDS.
# Only EKS app nodes can connect — nothing else, including you.
# To connect from your laptop, you'd need a bastion host (Phase 17).

resource "aws_security_group" "rds" {
  name        = "${local.identifier}-sg"
  description = "Controls access to RDS PostgreSQL - app tier only"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from app subnet only"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # Only the private app subnets can reach the database
    # Tighter than allowing all VPC traffic
    cidr_blocks = var.app_subnet_cidr_blocks
  }

  # RDS needs outbound to reach AWS services (backups, monitoring)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.common_tags, {
    Name = "${local.identifier}-sg"
  })
}

# ═══════════════════════════════════════════════════════════════
# DB SUBNET GROUP
# ═══════════════════════════════════════════════════════════════
# Tells RDS which subnets it can use for the primary and
# standby instances. Must span at least 2 AZs.

resource "aws_db_subnet_group" "main" {
  name        = "${local.identifier}-subnet-group"
  description = "DB subnet group for ${local.identifier}"
  subnet_ids  = var.database_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.identifier}-subnet-group"
  })
}

# ═══════════════════════════════════════════════════════════════
# RDS PARAMETER GROUP
# ═══════════════════════════════════════════════════════════════
# Parameter groups are like config files for PostgreSQL.
# We create a custom one so we can tune settings later
# without replacing the RDS instance (which causes downtime).

resource "aws_db_parameter_group" "main" {
  name        = "${local.identifier}-params"
  family      = "postgres18"
  description = "Custom parameters for ${local.identifier}"

  parameter {
    # Log queries slower than 1 second — essential for performance debugging
    name  = "log_min_duration_statement"
    value = "1000"
    apply_method = "immediate"
  }

  tags = local.common_tags

  lifecycle {
    # Prevents destruction if parameter group is in use
     create_before_destroy = true
  }
}

# ═══════════════════════════════════════════════════════════════
# KMS KEY FOR RDS ENCRYPTION
# ═══════════════════════════════════════════════════════════════

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption — ${local.identifier}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name    = "${local.identifier}-kms-key"
    Purpose = "rds-encryption"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.identifier}"
  target_key_id = aws_kms_key.rds.key_id
}

# ═══════════════════════════════════════════════════════════════
# RDS INSTANCE
# ═══════════════════════════════════════════════════════════════

resource "aws_db_instance" "main" {
  identifier = local.identifier

  # Engine
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage — autoscaling means RDS grows automatically
  # when usage exceeds 90% of allocated_storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3" # gp3 = cheaper and faster than gp2

  # Encryption at rest — mandatory for production data
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # Database
  db_name  = var.db_name
  username = local.db_credentials["username"]
  password = local.db_credentials["password"]

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Never put RDS in a public subnet
  publicly_accessible = false

  # Custom parameter group we defined above
  parameter_group_name = aws_db_parameter_group.main.name

  # High Availability
  multi_az = var.multi_az

  # Backups
  backup_retention_period = var.backup_retention_days
  # Run backups at 3am UTC — low traffic window
  backup_window = "03:00-04:00"
  # Run maintenance (patches) Sunday 4am UTC
  maintenance_window = "sun:04:00-sun:05:00"

  # Monitoring
  # monitoring_interval = 60 means Enhanced Monitoring every 60 seconds
  # 0 = disabled, 1/5/10/15/30/60 = seconds between samples
  monitoring_interval = 60
  monitoring_role_arn = var.monitoring_role_arn

  # Performance Insights — query-level performance visibility
  performance_insights_enabled          = true
  performance_insights_retention_period = 7 # days (free tier)

  # Safety
  deletion_protection = var.deletion_protection
  # skip_final_snapshot = true in dev so terraform destroy doesn't hang
  # Always false in prod — you want a final backup before deletion
  skip_final_snapshot       = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment != "dev" ? "${local.identifier}-final-snapshot" : null

  tags = merge(local.common_tags, {
    Name = local.identifier
  })
}
