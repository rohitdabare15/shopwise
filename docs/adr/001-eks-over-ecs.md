# ADR 001: EKS over ECS

## Status: Accepted

## Context
Need a container orchestration platform for the shopwise application.

## Decision
Use Amazon EKS (managed Kubernetes) instead of Amazon ECS.

## Reasons
- Kubernetes is cloud-agnostic — skills transfer to any cloud
- Larger ecosystem: Helm charts, operators, tooling
- IRSA for pod-level IAM without credential management
- Industry standard for enterprise DevOps roles

## Trade-offs
- Higher complexity than ECS
- Slightly higher cost ($0.10/hr control plane)
- Longer initial setup time

## Alternatives rejected
- ECS Fargate: simpler but AWS-proprietary, limited K8s ecosystem
- Self-managed K8s: too much operational overhead
EOF

cat > docs/adr/002-terraform-modules.md << 'EOF'
# ADR 002: Modular Terraform Architecture

## Status: Accepted

## Context
Need Infrastructure as Code that supports multiple environments.

## Decision
Use Terraform with a modules-based architecture where each AWS service
(VPC, EKS, RDS, IAM, ECR) is a separate reusable module.

## Reasons
- Single module serves dev/staging/prod with different variables
- Each module is independently testable
- Prevents code duplication across environments
- Matches enterprise team structure (platform team owns modules)

## Trade-offs
- More initial setup vs monolithic main.tf
- Module interfaces require careful design

## Alternatives rejected
- Monolithic main.tf: unmaintainable at scale
- CloudFormation: AWS-only, verbose syntax
- CDK: adds programming language complexity
