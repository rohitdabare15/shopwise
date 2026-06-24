'README'
# Shopwise — Production-Grade DevOps Project

A complete end-to-end DevOps implementation of a 3-tier e-commerce application on AWS, demonstrating enterprise-grade infrastructure, CI/CD, and observability.

## Architecture

Internet → ALB → EKS (Frontend + Backend) → RDS PostgreSQL

↑

Jenkins CI/CD (ECR → EKS)

↑

Prometheus + Grafana + Loki (Monitoring)

## Technology Stack

| Layer | Technology |
|---|---|
| Cloud | AWS (EKS, RDS, ECR, ALB, VPC, IAM, KMS, Secrets Manager) |
| IaC | Terraform (modular, multi-environment) |
| Containers | Docker (multi-stage builds) |
| Orchestration | Kubernetes (EKS 1.31) |
| CI/CD | Jenkins |
| Monitoring | Prometheus + Grafana + AlertManager |
| Logging | Loki + Promtail |
| Frontend | React + Vite + Nginx |
| Backend | Python Flask + SQLAlchemy |
| Database | PostgreSQL 18 (RDS) |

## Project Structure

shopwise/

├── applications/          # Frontend (React) and Backend (Flask)

├── cicd/                  # Jenkinsfile and CI/CD scripts

├── infrastructure/

│   └── terraform/

│       ├── environments/  # dev, staging, prod configs

│       └── modules/       # vpc, eks, rds, iam, ecr, bastion

├── kubernetes/

│   ├── base/              # Deployments, Services, HPA, Ingress

│   └── monitoring/        # Prometheus rules, Grafana dashboards

└── docs/                  # Architecture and runbooks

## Quick Start

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- kubectl
- Helm
- Docker

### Deploy Dev Environment

```bash
# Clone the repository
git clone https://github.com/rohitdabare15/shopwise.git
cd shopwise

# Deploy infrastructure
cd infrastructure/terraform/environments/dev
terraform init
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name shopwise-dev

# Deploy application
bash infrastructure/scripts/rebuild-dev.sh
```

### Destroy Dev Environment

```bash
bash infrastructure/scripts/destroy-dev.sh
```

## Key Features Demonstrated

- **Enterprise VPC**: 3-tier subnet architecture across 3 AZs
- **Modular Terraform**: Reusable modules for VPC, EKS, RDS, IAM, ECR
- **Multi-environment**: Dev/staging/prod with separate state files
- **Security**: Non-root containers, network policies, KMS encryption, IRSA
- **CI/CD**: Jenkins pipeline with parallel builds, ECR push, rolling deploy
- **Observability**: Prometheus metrics, Loki logs, AlertManager alerts
- **Auto-scaling**: HPA for pods, Cluster Autoscaler for nodes
- **Cost optimisation**: Single NAT GW in dev, destroy/rebuild scripts

## Infrastructure Cost (Dev)

| Resource | $/hr |
|---|---|
| EKS Control Plane | $0.10 |
| 2x t3.medium nodes | $0.083 |
| RDS db.t3.micro | $0.017 |
| NAT Gateway | $0.045 |
| Jenkins t3.medium | $0.041 |
| **Total** | **~$0.29/hr** |

## Architecture Decisions

See [docs/adr/](docs/adr/) for Architecture Decision Records covering technology choices and trade-offs.

## Author

Rohit Dabare — [LinkedIn](https://linkedin.com/in/rohitdabare) | [GitHub](https://github.com/rohitdabare15)
README
