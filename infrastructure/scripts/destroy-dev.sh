#!/bin/bash
set -e

echo "============================================"
echo "  SHOPWISE DEV TEARDOWN"
echo "============================================"
echo ""
echo "Cost saved by destroying:"
echo "  EKS nodes:    ~\$0.083/hr"
echo "  NAT Gateway:  ~\$0.045/hr"  
echo "  RDS:          ~\$0.017/hr"
echo "  Jenkins EC2:  ~\$0.041/hr"
echo "  EKS control:  ~\$0.100/hr"
echo "  Total saved:  ~\$0.286/hr = \$2.29/8hr session"
echo ""

cd "$(dirname "$0")/../terraform/environments/dev"

read -p "Type 'destroy-dev' to confirm: " CONFIRM
if [ "$CONFIRM" != "destroy-dev" ]; then
  echo "Cancelled."
  exit 0
fi

# Scale down nodes first (faster than waiting for terraform)
echo "Scaling down EKS nodes..."
aws eks update-nodegroup-config \
  --cluster-name shopwise-dev \
  --nodegroup-name shopwise-dev-node-group \
  --scaling-config minSize=0,maxSize=0,desiredSize=0 \
  --region us-east-1 2>/dev/null || true

echo "Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "============================================"
echo "  TEARDOWN COMPLETE — charges stopped"
echo "  Rebuild: terraform apply"
echo "============================================"
