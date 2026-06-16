locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "iam"
  })

  cluster_name = var.eks_cluster_name
}

# ═══════════════════════════════════════════════════════════════
# EKS CONTROL PLANE ROLE
# ═══════════════════════════════════════════════════════════════
# This role is assumed by the EKS SERVICE ITSELF — not by your
# application or your nodes. EKS uses it to manage ENIs, security
# groups, and load balancers on your behalf.

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  # Trust policy: only the EKS service can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name    = "${var.project_name}-${var.environment}-eks-cluster-role"
    Purpose = "eks-control-plane"
  })
}

# AWS-managed policy that gives EKS the permissions it needs
# This policy is maintained by AWS — it updates when EKS adds features
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# ═══════════════════════════════════════════════════════════════
# EKS NODE GROUP ROLE
# ═══════════════════════════════════════════════════════════════
# This role is assumed by the EC2 INSTANCES (worker nodes) in
# your EKS cluster. Nodes need to:
# 1. Register themselves with the EKS cluster
# 2. Pull container images from ECR
# 3. Write logs and metrics to CloudWatch

resource "aws_iam_role" "eks_node" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

  # Trust policy: EC2 instances can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name    = "${var.project_name}-${var.environment}-eks-node-role"
    Purpose = "eks-worker-nodes"
  })
}

# Three AWS-managed policies required for EKS worker nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  # Allows node to describe EC2 resources, register with cluster
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  # Allows the VPC CNI plugin to manage pod networking (assign IPs to pods)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  # Allows nodes to pull images from ANY ECR repository in your account
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

# CloudWatch agent — nodes send metrics and logs to CloudWatch
resource "aws_iam_role_policy_attachment" "eks_cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_node.name
}

# ═══════════════════════════════════════════════════════════════
# IRSA — IAM ROLES FOR SERVICE ACCOUNTS
# ═══════════════════════════════════════════════════════════════
# IRSA is the Kubernetes-native way to give individual PODS
# access to AWS services — without sharing credentials with the
# entire node.
#
# How it works:
# 1. EKS has an OIDC provider (like a trusted identity server)
# 2. A Kubernetes ServiceAccount is annotated with an IAM Role ARN
# 3. When a pod starts, it gets a short-lived token
# 4. The pod exchanges that token for AWS credentials via STS
# 5. AWS only issues credentials if the OIDC token matches the
#    trust policy — pod identity is cryptographically verified
#
# Result: Pod A (frontend) has zero AWS access.
#         Pod B (backend) can only read from Secrets Manager.
#         Neither can access S3, even though they're on the same node.

resource "aws_iam_role" "app_backend" {
  name = "${var.project_name}-${var.environment}-backend-pod-role"

  # Trust policy: only the backend ServiceAccount in the app namespace
  # can assume this role. The OIDC condition makes it pod-specific.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.eks_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # Format: "<oidc-url>:sub" = "system:serviceaccount:<namespace>:<sa-name>"
          "${var.eks_oidc_provider_url}:sub" = "system:serviceaccount:shopwise:backend-sa"
          "${var.eks_oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name    = "${var.project_name}-${var.environment}-backend-pod-role"
    Purpose = "irsa-backend"
  })
}

# What the backend pod is allowed to do
resource "aws_iam_policy" "app_backend" {
  name        = "${var.project_name}-${var.environment}-backend-pod-policy"
  description = "Allows backend pods to read secrets and write to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read database credentials from Secrets Manager
        Sid    = "ReadSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.project_name}/${var.environment}/*"
        ]
      },
      {
        # Write product images and user uploads to S3
        Sid    = "S3AppBucket"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-app-data",
          "arn:aws:s3:::${var.project_name}-${var.environment}-app-data/*"
        ]
      },
      {
        # Write application metrics to CloudWatch
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "app_backend" {
  policy_arn = aws_iam_policy.app_backend.arn
  role       = aws_iam_role.app_backend.name
}

# ═══════════════════════════════════════════════════════════════
# JENKINS DEPLOYMENT ROLE
# ═══════════════════════════════════════════════════════════════
# Jenkins needs to:
# 1. Push Docker images to ECR
# 2. Update EKS deployments (kubectl apply)
# 3. Read from Secrets Manager to inject into pipeline
#
# Jenkins runs on EC2, so it assumes a role — no static keys.

resource "aws_iam_role" "jenkins" {
  name = "${var.project_name}-${var.environment}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name    = "${var.project_name}-${var.environment}-jenkins-role"
    Purpose = "cicd-jenkins"
  })
}

resource "aws_iam_policy" "jenkins" {
  name        = "${var.project_name}-${var.environment}-jenkins-policy"
  description = "Allows Jenkins to push images to ECR and deploy to EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # ECR authentication and image push
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = "*"
        # Note: GetAuthorizationToken cannot be scoped to a specific repo
        # All other actions can be scoped — we'll tighten this in Phase 17
      },
      {
        # EKS — describe cluster to get kubeconfig credentials
        Sid    = "EKSDescribe"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "arn:aws:eks:${var.aws_region}:${var.aws_account_id}:cluster/${local.cluster_name}"
      },
      {
        # Secrets Manager — read pipeline secrets (Docker Hub fallback, webhook tokens)
        Sid    = "SecretsRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.project_name}/jenkins/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "jenkins" {
  policy_arn = aws_iam_policy.jenkins.arn
  role       = aws_iam_role.jenkins.name
}

# Instance profile wraps the role so EC2 can assume it
# (EC2 requires an instance profile, not a role directly)
resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project_name}-${var.environment}-jenkins-profile"
  role = aws_iam_role.jenkins.name

  tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════
# RDS MONITORING ROLE
# ═══════════════════════════════════════════════════════════════
# Allows RDS Enhanced Monitoring to send OS-level metrics
# (CPU, memory, disk, network per process) to CloudWatch Logs.

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name    = "${var.project_name}-${var.environment}-rds-monitoring-role"
    Purpose = "rds-enhanced-monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.rds_monitoring.name
}
