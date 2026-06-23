locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "ecr"
  })
}

resource "aws_ecr_repository" "main" {
  for_each = toset(var.repositories)

  name                 = "${var.project_name}/${each.value}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  # Scan images for CVEs on every push
  # Results appear in the ECR console and can trigger alerts
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt images at rest using KMS
  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}/${each.value}"
  })
}

# Lifecycle policy — automatically delete old images
# Without this, every push accumulates forever and costs money
resource "aws_ecr_lifecycle_policy" "main" {
  for_each   = aws_ecr_repository.main
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
