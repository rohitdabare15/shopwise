# ─── Local values ────────────────────────────────────────────────────────────
# Locals are computed values we use repeatedly below.
# Defining them once here prevents mistakes from copy-pasting.

locals {
  # Merge caller-provided tags with mandatory tags every resource must have
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "vpc"
  })

  # If single_nat_gateway = true, we only create 1 NAT GW (in the first AZ).
  # If false, we create one per AZ (production best practice).
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.availability_zones)
}

# ─── VPC ─────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # enable_dns_hostnames = true lets EC2 instances get DNS names like
  # ip-10-0-1-5.ec2.internal — required for EKS to work correctly
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
    # EKS requires this tag to discover the VPC
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  })
}

# ─── Internet Gateway ─────────────────────────────────────────────────────────
# The IGW is the door between your VPC and the internet.
# Without it, nothing in your VPC can communicate with the outside world.
# One IGW per VPC — it's not per-subnet or per-AZ.

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# ─── Public Subnets ───────────────────────────────────────────────────────────
# count = length(var.availability_zones) means we create one subnet per AZ.
# count.index lets us pick the right CIDR and AZ for each one.

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # map_public_ip_on_launch = true means any EC2 in this subnet
  # gets a public IP automatically. Required for the ALB.
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    Type = "public"
    # ALB controller uses this tag to discover which subnets to use for internet-facing ALBs
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  })
}

# ─── Private App Subnets (EKS Nodes) ─────────────────────────────────────────

resource "aws_subnet" "private_app" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # map_public_ip_on_launch = false — these nodes never get public IPs
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-app-${var.availability_zones[count.index]}"
    Type = "private-app"
    # Internal load balancer tag — used when creating internal ALBs or NLBs
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  })
}

# ─── Private DB Subnets (RDS) ─────────────────────────────────────────────────

resource "aws_subnet" "private_db" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-db-${var.availability_zones[count.index]}"
    Type = "private-db"
  })
}

# ─── Elastic IPs for NAT Gateways ─────────────────────────────────────────────
# A NAT Gateway needs a static public IP address.
# EIP (Elastic IP) is AWS's static public IP service.

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  # depends_on ensures the IGW exists before we create the EIP
  # (EIPs in a VPC context need the IGW to be attached first)
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  })
}

# ─── NAT Gateways ─────────────────────────────────────────────────────────────
# NAT GW lives in a PUBLIC subnet but serves PRIVATE subnets.
# Private subnet instances send outbound traffic → NAT GW → Internet Gateway → Internet
# Return traffic comes back the same path in reverse.
# Inbound connections from the internet are BLOCKED — that's the security model.

resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  # Place NAT GW in the first public subnet (or one per AZ if nat_gateway_count > 1)
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# ─── Route Table: Public ──────────────────────────────────────────────────────
# One route table for all public subnets.
# Rule: all traffic to 0.0.0.0/0 (any internet address) → Internet Gateway

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rt-public"
  })
}

# Associate every public subnet with the public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─── Route Tables: Private App ────────────────────────────────────────────────
# One route table per AZ (or one shared if single_nat_gateway = true).
# Rule: all internet traffic → NAT Gateway (not the IGW directly)

resource "aws_route_table" "private_app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    # If single NAT GW, all AZs use index 0. If one per AZ, use matching index.
    nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rt-private-app-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table_association" "private_app" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# ─── Route Tables: Private DB ─────────────────────────────────────────────────
# Database subnets have NO internet route at all.
# RDS instances only talk to the app tier within the VPC — never to the internet.

resource "aws_route_table" "private_db" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  # No routes added — only the implicit local VPC route exists (10.0.0.0/16 → local)
  # This means RDS can only receive connections from within the VPC

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rt-private-db-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table_association" "private_db" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db[count.index].id
}

# ─── VPC Flow Logs ────────────────────────────────────────────────────────────
# Flow logs record every network connection in/out of your VPC.
# Essential for security audits and debugging "why can't X talk to Y".

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type    = "ALL"  # Capture ACCEPT and REJECT traffic
  vpc_id          = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}/flow-logs"
  retention_in_days = 30  # Keep 30 days — enough for security investigations

  tags = local.common_tags
}

# IAM role that allows VPC to write logs to CloudWatch
resource "aws_iam_role" "flow_log" {
  name = "${var.project_name}-${var.environment}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${var.project_name}-${var.environment}-vpc-flow-log-policy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}
