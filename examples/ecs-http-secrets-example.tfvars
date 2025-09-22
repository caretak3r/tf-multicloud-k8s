# ECS HTTP Server with Secrets Sidecar Example Configuration
# 
# This example demonstrates deploying:
# 1. HTTP server service that communicates with a secrets sidecar
# 2. Secrets sidecar service that fetches secrets from AWS Secrets Manager
# 3. Self-signed certificates for HTTPS communication
# 4. Load balancer with SSL termination

# Basic Configuration
cloud_provider = "aws"
aws_region     = "us-west-2"
cluster_name   = "http-secrets-cluster"
environment    = "development"

# Module Control
enable_eks         = false
enable_ecs         = true
enable_bastion     = true
enable_nat_gateway = true
enable_vpc_endpoints = true

# VPC Configuration
create_vpc               = true
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2

# ============================================================================
# HTTP SERVER SERVICE CONFIGURATION
# ============================================================================

# Container Configuration
ecs_container_image = "nginx:latest"  # Replace with your HTTP server image
ecs_container_port  = 443             # HTTPS port for secure communication
ecs_task_cpu        = 512             # 0.5 vCPU
ecs_task_memory     = 1024            # 1GB RAM
ecs_desired_count   = 2

# Enable Secrets Sidecar
ecs_enable_secrets_sidecar = true
ecs_secrets_sidecar_image = "amazon/aws-cli:latest"  # Replace with secrets sidecar image

# Secrets Configuration - These will be created in AWS Secrets Manager
ecs_secrets_prefix = "http-server/"
ecs_secrets = {
  database_password    = "my-secure-db-password"
  api_key             = "sk-1234567890abcdefghijklmnop"
  jwt_signing_key     = "super-secret-jwt-key-for-token-signing"
  redis_password      = "redis-secure-password-123"
  encryption_key      = "32-char-aes256-encryption-key!!"
  oauth_client_secret = "oauth-app-client-secret-value"
  smtp_password       = "email-service-password-secure"
  third_party_api_key = "3rd-party-service-api-key-123"
}

# Environment Variables (non-sensitive configuration)
ecs_environment_variables = [
  {
    name  = "APP_ENV"
    value = "development"
  },
  {
    name  = "LOG_LEVEL"
    value = "info"
  },
  {
    name  = "PORT"
    value = "443"
  },
  {
    name  = "SERVICE_NAME"
    value = "http-server"
  },
  {
    name  = "ENABLE_HTTPS"
    value = "true"
  },
  {
    name  = "CERT_PATH"
    value = "/etc/ssl/certs/server.crt"
  },
  {
    name  = "KEY_PATH"
    value = "/etc/ssl/private/server.key"
  },
  {
    name  = "SECRETS_SIDECAR_URL"
    value = "http://localhost:8080"
  },
  {
    name  = "SECRETS_REFRESH_INTERVAL"
    value = "300"
  }
]

# ============================================================================
# LOAD BALANCER AND CERTIFICATE CONFIGURATION
# ============================================================================

# Health Check Configuration
ecs_health_check_path = "/health"

# Load Balancer Configuration
ecs_internal_alb        = false                # Public-facing ALB
ecs_allowed_cidr_blocks = ["0.0.0.0/0"]       # Allow all traffic (adjust for production)

# SSL Certificate Configuration
ecs_create_self_signed_cert = true
ecs_domain_name            = "http-server.example.local"

# Security Configuration
ecs_enable_waf                = true
ecs_rate_limit_per_5min       = 1000
ecs_enable_deletion_protection = false
ecs_ssl_policy                = "ELBSecurityPolicy-TLS-1-2-2017-01"

# ============================================================================
# BASTION HOST CONFIGURATION
# ============================================================================

bastion_key_name                = "my-key-pair"              # Create this key pair in AWS first
bastion_instance_type           = "t3.micro"
bastion_allowed_ssh_cidr_blocks = ["0.0.0.0/0"]             # Restrict to your IP in production

# ============================================================================
# SHARED CONFIGURATION
# ============================================================================

# Logging
log_retention_in_days = 14

# Resource Tagging
tags = {
  Environment = "development"
  Project     = "http-secrets-demo"
  Owner       = "devops-team"
  ManagedBy   = "terraform"
  Purpose     = "ecs-http-server-with-secrets-sidecar"
}

# ============================================================================
# DEPLOYMENT NOTES
# ============================================================================
#
# Before deploying, ensure you have:
# 1. Created an AWS key pair named "my-key-pair" (or update the name above)
# 2. Run the setup scripts to create certificates and secrets:
#    - ./scripts/generate-certificates.sh
#    - ./scripts/setup-secrets.sh
# 3. Built and pushed your HTTP server and secrets sidecar images to ECR
#
# Deploy with:
# terraform apply -var-file="examples/ecs-http-secrets-example.tfvars"
#
# The deployment creates:
# - VPC with public/private subnets across 2 AZs
# - ECS cluster with Fargate tasks
# - HTTP server container with mounted SSL certificates
# - Secrets sidecar container for secure secrets retrieval
# - Application Load Balancer with SSL termination
# - Security groups allowing HTTPS traffic
# - CloudWatch log groups for monitoring
# - Bastion host for secure access
#
# After deployment:
# - Access your service via the ALB DNS name (HTTPS)
# - SSH to bastion host to troubleshoot if needed
# - Monitor logs in CloudWatch