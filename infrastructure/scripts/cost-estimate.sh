'EOF'
#!/bin/bash
# cost-estimate.sh — shows current AWS costs for shopwise resources

echo "=== Shopwise Dev Environment Cost Estimate ==="
echo ""

# NAT Gateway — biggest cost item
echo "Checking NAT Gateway uptime..."
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=shopwise" \
             "Name=tag:Environment,Values=dev" \
  --query 'NatGateways[*].{State:State,Created:CreateTime,IP:NatGatewayAddresses[0].PublicIp}' \
  --output table

echo ""
echo "Cost rates (us-east-1):"
echo "  NAT Gateway:   \$0.045/hr = \$1.08/day = \$32.40/month"
echo "  Elastic IP:    \$0.005/hr (free while attached to running NAT GW)"
echo "  VPC/Subnets:   \$0.00"
echo "  Flow Logs:     ~\$0.50/GB ingested"
echo ""
echo "Current Phase 3 only:  ~\$1.10/day when running"
echo "After Phase 6 (EKS):   ~\$8.00/day when running"
echo "After Phase 7 (RDS):   ~\$9.50/day when running"
EOF
