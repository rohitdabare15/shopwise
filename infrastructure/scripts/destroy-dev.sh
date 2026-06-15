'EOF'
#!/bin/bash
# destroy-dev.sh — safely tears down dev environment to stop AWS charges
# Run this at the end of every session

set -e  # Exit immediately if any command fails

echo "============================================"
echo "  SHOPWISE DEV ENVIRONMENT TEARDOWN"
echo "============================================"
echo ""
echo "This will destroy ALL dev resources."
echo "Your Terraform code is safe — only AWS resources are deleted."
echo ""

# Safety check — confirm you're destroying dev, not prod
CURRENT_DIR=$(pwd)
if [[ "$CURRENT_DIR" != *"environments/dev"* ]]; then
  echo "ERROR: Run this script from infrastructure/terraform/environments/dev/"
  echo "Current directory: $CURRENT_DIR"
  exit 1
fi

# Show what will be destroyed
echo "Resources that will be destroyed:"
terraform show | grep "# aws_" | sed 's/# /  - /'
echo ""

read -p "Type 'destroy-dev' to confirm: " CONFIRM
if [ "$CONFIRM" != "destroy-dev" ]; then
  echo "Cancelled."
  exit 0
fi

echo ""
echo "Starting destruction..."
terraform destroy -auto-approve

echo ""
echo "============================================"
echo "  TEARDOWN COMPLETE"
echo "  All dev resources destroyed."
echo "  Run 'terraform apply' to rebuild."
echo "============================================"
EOF
