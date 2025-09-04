# Secure ECS Deployment with ALB, Secrets Manager, and TLS
# This example shows deployment of an ECS cluster in existing VPC with:
# - Main service on port 50051 (mapped from ALB 443)
# - Secrets broker sidecar on port 8080
# - TLS certificates for inter-container communication
# - Comprehensive secrets management via AWS Secrets Manager
# - Secure keypair and certificate generation scripts

# Basic Configuration
cloud_provider = "aws"
aws_region     = "us-west-2"
cluster_name   = "secure-app"
environment    = "production"

# Module Control - Enable ECS with existing VPC
enable_eks         = false
enable_ecs         = true
enable_bastion     = true
enable_nat_gateway = true
enable_vpc_endpoints = true

# Existing VPC Configuration
# Set create_vpc = false to use existing VPC
create_vpc = false
# Specify your existing VPC ID
existing_vpc_id = "vpc-0123456789abcdef0"
# Specify existing subnet IDs (private subnets for ECS tasks)
existing_private_subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0fedcba9876543210"
]
# Specify existing public subnet IDs (for ALB)
existing_public_subnet_ids = [
  "subnet-0abcdef0123456789",
  "subnet-09876543210fedcba"
]

# ECS Service Configuration
ecs_container_image         = "your-account.dkr.ecr.us-west-2.amazonaws.com/your-app:latest"
ecs_container_port          = 50051  # Main service port
ecs_task_cpu                = 2048   # 2 vCPU
ecs_task_memory             = 4096   # 4GB RAM
ecs_desired_count           = 2      # Number of tasks
ecs_enable_secrets_sidecar  = true   # Enable secrets broker on port 8080

# Secrets Configuration
# All secrets will be stored under this prefix in AWS Secrets Manager
ecs_secrets_prefix = "secure-app/prod/"

# Product and Platform Credentials
# These will be uploaded using the upload-secrets.sh script
ecs_secrets = {
  # Product Credentials
  product_client_id     = "/secure-app/prod/product_client_id"
  product_secret_key    = "/secure-app/prod/product_secret_key"
  
  # Platform Credentials  
  platform_client_id    = "/secure-app/prod/platform_client_id"
  platform_secret_key   = "/secure-app/prod/platform_secret_key"
  
  # TLS Certificates (uploaded via generate-certs.sh script)
  ssl_certificate       = "/secure-app/prod/ssl_certificate"
  ssl_private_key      = "/secure-app/prod/ssl_private_key"
  
  # Additional application secrets
  database_url          = "/secure-app/prod/database_url"
  redis_password        = "/secure-app/prod/redis_password"
  jwt_signing_key       = "/secure-app/prod/jwt_signing_key"
  encryption_key        = "/secure-app/prod/encryption_key"
}

# Environment Variables
ecs_environment_variables = [
  {
    name  = "APP_ENV"
    value = "production"
  },
  {
    name  = "PORT"
    value = "50051"
  },
  {
    name  = "SECRETS_BROKER_PORT"
    value = "8080"
  },
  {
    name  = "SERVICE_NAME"
    value = "secure-app"
  },
  {
    name  = "LOG_LEVEL"
    value = "info"
  },
  {
    name  = "ENABLE_TLS"
    value = "true"
  }
]

# ALB Configuration - Maps 443 to service port 50051
ecs_health_check_path    = "/health"
ecs_internal_alb         = false  # Public-facing ALB
ecs_allowed_cidr_blocks  = ["0.0.0.0/0"]

# SSL Certificate Configuration
# Option 1: Use existing ACM certificate ARN (recommended for production)
ecs_acm_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/your-cert-id"

# Option 2: Use generated self-signed certificate (for development/testing)
# ecs_create_self_signed_cert = true
# ecs_domain_name            = "api.your-domain.com"

# Security Configuration
ecs_enable_waf              = true
ecs_rate_limit_per_5min     = 3000
ecs_enable_deletion_protection = true

# Bastion Configuration (uses generated keypair)
bastion_key_name                = "secure-app-keypair"
bastion_instance_type           = "t3.micro"
bastion_allowed_ssh_cidr_blocks = [
  "10.0.0.0/8",     # Internal networks
  "172.16.0.0/12",  # Private networks
  "192.168.0.0/16"  # Local networks
]

# Logging Configuration
log_retention_in_days = 30

# Resource Tags
tags = {
  Environment   = "production"
  Project      = "secure-app"
  Service      = "main-api"
  ManagedBy    = "terraform"
  Owner        = "devops-team@company.com"
  CostCenter   = "engineering"
  Compliance   = "required"
  TLS          = "enabled"
}

# ============================================================================
# DEPLOYMENT INSTRUCTIONS
# ============================================================================
#
# Before running terraform apply, execute these scripts in order:
#
# 1. Generate secure keypair:
#    ./create-keypair.sh
#
# 2. Generate and upload TLS certificates:
#    ./generate-certs.sh
#
# 3. Upload product and platform credentials:
#    ./upload-secrets.sh
#
# 4. Deploy infrastructure:
#    terraform init
#    terraform plan -var-file="aws-ecs-secure-deployment.tfvars"
#    terraform apply -var-file="aws-ecs-secure-deployment.tfvars"
#
# ============================================================================
# SECRETS PATHS CONFIGURATION
# ============================================================================
#
# All secrets are organized under the prefix: secure-app/prod/
#
# Product Credentials:
# - /secure-app/prod/product_client_id
# - /secure-app/prod/product_secret_key
#
# Platform Credentials:
# - /secure-app/prod/platform_client_id  
# - /secure-app/prod/platform_secret_key
#
# TLS Certificates:
# - /secure-app/prod/ssl_certificate
# - /secure-app/prod/ssl_private_key
#
# Application Secrets:
# - /secure-app/prod/database_url
# - /secure-app/prod/redis_password
# - /secure-app/prod/jwt_signing_key
# - /secure-app/prod/encryption_key
#
# ============================================================================
# SERVICE ARCHITECTURE
# ============================================================================
#
# ALB (Port 443) -> ECS Service (Port 50051)
# |
# +-- Main Application Container (Port 50051)
# +-- Secrets Broker Sidecar (Port 8080)
#
# Inter-container communication uses TLS certificates stored in Secrets Manager
# Main service communicates with secrets broker via localhost:8080
#
# ============================================================================