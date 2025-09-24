# Data source to get subnet details
data "aws_subnet" "selected" {
  for_each = toset(var.internal_alb ? var.private_subnet_ids : var.public_subnet_ids)
  id       = each.value
}

# Local to ensure unique availability zones
locals {
  # Get unique AZs from the selected subnets
  subnet_azs = {
    for subnet_id, subnet in data.aws_subnet.selected :
    subnet_id => subnet.availability_zone
  }

  # Group subnets by AZ and take only the first subnet from each AZ
  unique_az_subnets = [
    for az in distinct(values(local.subnet_azs)) : [
      for subnet_id, subnet_az in local.subnet_azs :
      subnet_id if subnet_az == az
    ][0]
  ]
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = var.internal_alb
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.unique_az_subnets

  enable_deletion_protection = var.enable_deletion_protection

  # Security best practices
  drop_invalid_header_fields = true

  tags = var.tags
}

# Data source for VPC CIDR
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  vpc_id      = var.vpc_id

  # HTTP redirect to HTTPS
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.internal_alb && length(var.allowed_cidr_blocks) == 1 && var.allowed_cidr_blocks[0] == "0.0.0.0/0" ? [data.aws_vpc.main.cidr_block] : var.allowed_cidr_blocks
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.internal_alb && length(var.allowed_cidr_blocks) == 1 && var.allowed_cidr_blocks[0] == "0.0.0.0/0" ? [data.aws_vpc.main.cidr_block] : var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.cluster_name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = var.tags
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# WAF Web ACL (optional)
resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0
  name  = "${var.cluster_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rule - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_per_5min
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.cluster_name}WAFMetric"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "main" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main[0].arn
}