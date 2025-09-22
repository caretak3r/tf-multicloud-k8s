# ECS Cluster in Existing VPC with ALB and Self-Signed Certs
# Environment: Sandbox, Region: us-west-2
# Uses existing VPC, private subnets, and ACM certificate for ALB
# Creates self-signed certificates for service containers

# Basic Configuration
cloud_provider = "aws"
aws_region     = "us-west-2"
cluster_name   = "sandbox-ecs-cluster"
environment    = "sandbox"

# Module Control - Enable ECS only
enable_eks         = false
enable_ecs         = true
enable_bastion     = false
enable_nat_gateway = false
enable_vpc_endpoints = false

# Existing VPC Configuration
create_vpc = false
# Replace with your existing VPC ID
vpc_id = "vpc-0123456789abcdef0"

# Replace with your existing private subnet IDs
private_subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0123456789abcdef1",
  "subnet-0123456789abcdef2"
]

# Replace with your existing public subnet IDs (for ALB)
public_subnet_ids = [
  "subnet-abcdef0123456789a",
  "subnet-abcdef0123456789b", 
  "subnet-abcdef0123456789c"
]

# ECS Service Configuration
ecs_container_image         = "123456789012.dkr.ecr.us-west-2.amazonaws.com/main-service:latest"
ecs_container_port          = 50051
ecs_task_cpu                = 1024  # 1 vCPU
ecs_task_memory             = 2048  # 2GB RAM
ecs_desired_count           = 2     # 2 instances
ecs_enable_secrets_sidecar  = true  # Enable secrets sidecar container

# Sidecar Configuration (ECR image)
ecs_secrets_sidecar_image = "123456789012.dkr.ecr.us-west-2.amazonaws.com/sidecar-service:latest"

# Environment Variables
ecs_environment_variables = [
  {
    name  = "APP_ENV"
    value = "sandbox"
  },
  {
    name  = "LOG_LEVEL"
    value = "debug"
  },
  {
    name  = "PORT"
    value = "50051"
  },
  {
    name  = "SERVICE_NAME"
    value = "main-service"
  },
  {
    name  = "ENABLE_METRICS"
    value = "true"
  }
]

# ALB Configuration - Front main service on 443:50051 with wildcard route
ecs_health_check_path    = "/health"
ecs_internal_alb         = false  # Public-facing ALB
ecs_allowed_cidr_blocks  = ["0.0.0.0/0"]  # Allow from anywhere

# SSL Certificate Configuration
# Use existing ACM certificate for ALB
ecs_acm_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Create self-signed certificate for service containers
ecs_create_self_signed_cert = true
ecs_domain_name            = "sandbox-ecs-cluster.local"

# Security Configuration
ecs_enable_waf              = false  # Disabled for sandbox
ecs_rate_limit_per_5min     = 1000   # Lower rate limit for sandbox
ecs_enable_deletion_protection = false  # Allow deletion in sandbox

# Logging Configuration
log_retention_in_days = 7  # Short retention for sandbox

# Tags
tags = {
  Environment   = "sandbox"
  Project      = "ecs-deployment"
  Service      = "main-service"
  ManagedBy    = "terraform"
  Owner        = "devops-team"
  Purpose      = "testing"
}

# ============================================================================
# CONFIGURATION NOTES
# ============================================================================
#
# REQUIRED UPDATES BEFORE DEPLOYMENT:
#
# 1. VPC Configuration:
#    - Update vpc_id with your existing VPC ID
#    - Update private_subnet_ids with your existing private subnet IDs
#    - Update public_subnet_ids with your existing public subnet IDs
#
# 2. ECR Images:
#    - Update ecs_container_image with your main service ECR image URI
#    - Update ecs_secrets_sidecar_image with your sidecar ECR image URI
#
# 3. ACM Certificate:
#    - Update ecs_acm_certificate_arn with your existing ACM certificate ARN
#
# ALB Configuration:
# - ALB will listen on port 443 (HTTPS) using the ACM certificate
# - All requests will be forwarded to the main service on port 50051
# - Wildcard routing means all paths /* will go to the main service
#
# Certificate Setup:
# - ALB uses existing ACM certificate for HTTPS termination
# - ECS service containers get self-signed certificates for internal communication
#
# ============================================================================