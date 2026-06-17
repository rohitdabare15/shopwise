locals {
  cluster_name = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "eks"
  })
}

# ═══════════════════════════════════════════════════════════════
# EKS CLUSTER
# ═══════════════════════════════════════════════════════════════

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids = var.private_subnet_ids

    # endpoint_private_access = true means kubectl traffic
    # stays inside the VPC — never traverses the public internet
    endpoint_private_access = true

    # endpoint_public_access = true allows you to run kubectl
    # from your laptop. In prod you'd set this to false and use
    # a bastion host or VPN. For dev, public access is acceptable.
    endpoint_public_access = true

    # Restricts public API access to your IP only
    # We'll tighten this in Phase 17 (Security Hardening)
    public_access_cidrs = ["0.0.0.0/0"]
  }

  # Send all control plane logs to CloudWatch
  # Invaluable for debugging authentication and scheduling issues
  enabled_cluster_log_types = var.cluster_log_types

  # Encrypt Kubernetes secrets at rest using AWS KMS
  # Without this, K8s Secret objects are base64 in etcd — not encrypted
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })

  # Ensure IAM role is fully configured before cluster creation
  depends_on = [aws_cloudwatch_log_group.eks_cluster]
}

# ═══════════════════════════════════════════════════════════════
# KMS KEY FOR EKS SECRET ENCRYPTION
# ═══════════════════════════════════════════════════════════════
# Kubernetes Secrets (passwords, tokens, API keys) are stored
# in etcd. Without KMS encryption, they're only base64-encoded
# — trivially decoded. KMS encrypts them with a managed key.

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption — ${local.cluster_name}"
  deletion_window_in_days = 7 # 7-day safety window before permanent deletion

  # Key rotation every 365 days — security best practice
  enable_key_rotation = true

  tags = merge(local.common_tags, {
    Name    = "${local.cluster_name}-eks-secrets-key"
    Purpose = "eks-secrets-encryption"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# ═══════════════════════════════════════════════════════════════
# CLOUDWATCH LOG GROUP FOR EKS CONTROL PLANE
# ═══════════════════════════════════════════════════════════════
# EKS requires this log group to exist before the cluster
# can ship logs. We create it explicitly to control retention.

resource "aws_cloudwatch_log_group" "eks_cluster" {
  # AWS requires this exact naming convention for EKS logs
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 30

  tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════
# EKS NODE GROUP
# ═══════════════════════════════════════════════════════════════
# A managed node group is an Auto Scaling Group of EC2 instances
# that AWS keeps patched and registers with your cluster.
# "Managed" means AWS handles node lifecycle — you just set sizes.

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.cluster_name}-node-group"
  node_role_arn   = var.node_role_arn

  # Nodes go into private subnets — they never get public IPs
  subnet_ids = var.private_subnet_ids

  # Instance configuration
  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  # AMI type: AL2_x86_64 = Amazon Linux 2, optimised for EKS
  # AWS maintains this AMI and patches it automatically
  ami_type = "AL2_x86_64"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  # Rolling update strategy — replaces nodes one at a time
  # max_unavailable = 1 means at most 1 node is down during updates
  update_config {
    max_unavailable = 1
  }

  labels = {
    Environment = var.environment
    NodeGroup   = "main"
    Project     = var.project_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-node-group"
    # Required tag for Cluster Autoscaler discovery (Phase 16)
    "k8s.io/cluster-autoscaler/enabled"               = "true"
    "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
  })
}

# ═══════════════════════════════════════════════════════════════
# OIDC PROVIDER
# ═══════════════════════════════════════════════════════════════
# The OIDC provider is what makes IRSA work (Phase 5 IAM roles).
# It tells AWS: "trust Kubernetes tokens from this cluster
# as proof of pod identity when issuing temporary credentials."
#
# Without this, pods cannot assume IAM roles at all.

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-oidc-provider"
  })
}

# ═══════════════════════════════════════════════════════════════
# SECURITY GROUP FOR CLUSTER ADDITIONAL TRAFFIC
# ═══════════════════════════════════════════════════════════════
# EKS creates its own security groups, but we add one for
# any additional traffic rules we need (e.g. monitoring)

resource "aws_security_group" "eks_additional" {
  name        = "${local.cluster_name}-additional-sg"
  description = "Additional rules for EKS cluster traffic"
  vpc_id      = var.vpc_id

  # Allow all outbound — nodes need to reach ECR, S3, CloudWatch
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-additional-sg"
  })
}
