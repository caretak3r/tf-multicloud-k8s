data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Data source for existing VPC when create_vpc = false
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.vpc_id
}

# VPC resource when create_vpc = true
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Private subnets when create_vpc = true
resource "aws_subnet" "private" {
  count = var.create_vpc && var.enable_private_subnets ? var.availability_zones_count : 0

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name                              = "${var.name_prefix}-private-${count.index + 1}"
    Type                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Public subnets when create_vpc = true
resource "aws_subnet" "public" {
  count = var.create_vpc && var.enable_public_subnets ? var.availability_zones_count : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                     = "${var.name_prefix}-public-${count.index + 1}"
    Type                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

# Internet Gateway when create_vpc = true
resource "aws_internet_gateway" "main" {
  count = var.create_vpc && var.enable_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# Elastic IPs for NAT Gateways when create_vpc = true
resource "aws_eip" "nat" {
  count = var.create_vpc && var.enable_nat_gateway && var.enable_private_subnets ? var.availability_zones_count : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateways when create_vpc = true
resource "aws_nat_gateway" "main" {
  count = var.create_vpc && var.enable_nat_gateway && var.enable_private_subnets && var.enable_public_subnets ? var.availability_zones_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Public route table when create_vpc = true
resource "aws_route_table" "public" {
  count = var.create_vpc && var.enable_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# Public route to Internet Gateway
resource "aws_route" "public_internet" {
  count = var.create_vpc && var.enable_public_subnets ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

# Private route tables when create_vpc = true
resource "aws_route_table" "private" {
  count = var.create_vpc && var.enable_private_subnets ? var.availability_zones_count : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
  })
}

# Private routes to NAT Gateways
resource "aws_route" "private_nat" {
  count = var.create_vpc && var.enable_private_subnets && var.enable_nat_gateway && var.enable_public_subnets ? var.availability_zones_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count = var.create_vpc && var.enable_public_subnets ? var.availability_zones_count : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count = var.create_vpc && var.enable_private_subnets ? var.availability_zones_count : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security group for VPC endpoints - only when create_vpc = true
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc && var.enable_vpc_endpoints ? 1 : 0

  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc-endpoints-sg"
  })
}

# S3 VPC Endpoint Policy Document
data "aws_iam_policy_document" "s3_endpoint_policy" {
  count = var.create_vpc && var.enable_vpc_endpoints ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalVpc"
      values   = [aws_vpc.main[0].id]
    }
  }
}

# VPC Endpoints - only when create_vpc = true
resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc && var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.main[0].id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    var.enable_private_subnets ? aws_route_table.private[*].id : [],
    var.enable_public_subnets ? [aws_route_table.public[0].id] : []
  )
  policy = data.aws_iam_policy_document.s3_endpoint_policy[0].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecr-dkr-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecr-api-endpoint"
  })
}

resource "aws_vpc_endpoint" "eks" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-endpoint"
  })
}

resource "aws_vpc_endpoint" "logs" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-logs-endpoint"
  })
}

resource "aws_vpc_endpoint" "sts" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sts-endpoint"
  })
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-elb-endpoint"
  })
}

resource "aws_vpc_endpoint" "autoscaling" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.autoscaling"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-autoscaling-endpoint"
  })
}

resource "aws_vpc_endpoint" "kms" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kms-endpoint"
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-secretsmanager-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssm" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ssm-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ssmmessages-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  count = var.create_vpc && var.enable_vpc_endpoints && var.enable_private_subnets ? 1 : 0

  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2messages-endpoint"
  })
}