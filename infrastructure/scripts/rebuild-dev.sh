#!/bin/bash
set -e

echo "=== Rebuilding Shopwise Dev Environment ==="

cd "$(dirname "$0")/../terraform/environments/dev"

# Rebuild infrastructure
terraform apply -auto-approve

# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name shopwise-dev

# Wait for nodes
echo "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes \
  --all --timeout=300s

# Redeploy application
cd ../../../../

# Recreate namespace and secrets
kubectl apply -f kubernetes/base/namespaces.yaml

DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "shopwise/dev/rds/master-password" \
  --query 'SecretString' \
  --output text | python -c "import sys,json; print(json.load(sys.stdin)['password'])")

kubectl create secret generic backend-secret \
  --namespace shopwise \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  --from-literal=SECRET_KEY="$(openssl rand -base64 32)" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f kubernetes/base/backend/serviceaccount.yaml
kubectl apply -f kubernetes/base/backend/configmap.yaml
kubectl apply -f kubernetes/base/frontend/configmap.yaml
kubectl apply -f kubernetes/base/network-policies.yaml

# Deploy apps
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"

sed "s|BACKEND_IMAGE_URL|${ECR_REGISTRY}/shopwise/backend|g" \
  kubernetes/base/backend/deployment.yaml | kubectl apply -f -
kubectl apply -f kubernetes/base/backend/service.yaml
kubectl apply -f kubernetes/base/backend/hpa.yaml

sed "s|FRONTEND_IMAGE_URL|${ECR_REGISTRY}/shopwise/frontend|g" \
  kubernetes/base/frontend/deployment.yaml | kubectl apply -f -
kubectl apply -f kubernetes/base/frontend/service.yaml
kubectl apply -f kubernetes/base/frontend/hpa.yaml

# Reinstall ALB controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=shopwise-dev \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=$(terraform -chdir=infrastructure/terraform/environments/dev output -raw vpc_id)

# Apply ingress
PUBLIC_SUBNETS=$(terraform -chdir=infrastructure/terraform/environments/dev \
  output -json public_subnet_ids | \
  python -c "import sys,json; print(','.join(json.load(sys.stdin)))")

sed "s|REPLACE_WITH_PUBLIC_SUBNET_IDS|${PUBLIC_SUBNETS}|g" \
  kubernetes/base/ingress/ingress.yaml | kubectl apply -f -

echo ""
echo "=== Rebuild complete ==="
echo "ALB URL (takes 3-5 min to provision):"
kubectl get ingress shopwise-ingress -n shopwise \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || \
  echo "Still provisioning..."
