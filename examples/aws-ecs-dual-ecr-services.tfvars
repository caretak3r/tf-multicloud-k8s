# Example: Dual ECS Services from ECR with Secrets Sidecar
# This example deploys two services from ECR registry where images already exist:
# - Service 1: Main application with secrets and certificates via sidecar (4 vCPU, 4GB RAM)
# - Service 2: Lightweight service without secrets sidecar (200m vCPU, 200MB RAM)

# Basic Configuration
cloud_provider = "aws"
aws_region     = "us-west-2"
cluster_name   = "dual-ecr-services"
environment    = "production"

# Module Control - Enable ECS only
enable_eks         = false
enable_ecs         = true
enable_bastion     = true
enable_nat_gateway = true
enable_vpc_endpoints = true

# VPC Configuration
create_vpc               = true
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 3

# Main Service Configuration (Service 1 - with secrets sidecar)
# Uses 4 vCPU and 4GB RAM, gets secrets and certs via sidecar
ecs_container_image         = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-main-app:latest"
ecs_container_port          = 50001
ecs_task_cpu                = 4096  # 4 vCPU
ecs_task_memory             = 4096  # 4GB RAM
ecs_desired_count           = 2
ecs_enable_secrets_sidecar  = true

# Secrets Configuration for Service 1
ecs_secrets_prefix = "main-app/"
ecs_secrets = {
  database_password    = "super-secret-db-password"
  api_key             = "your-external-api-key"
  encryption_key      = "your-32-char-encryption-key-here"
  jwt_secret          = "jwt-signing-secret-key"
  oauth_client_secret = "oauth-provider-client-secret"
}

# Environment Variables for Service 1
ecs_environment_variables = [
  {
    name  = "APP_ENV"
    value = "production"
  },
  {
    name  = "LOG_LEVEL"
    value = "info"
  },
  {
    name  = "PORT"
    value = "50001"
  },
  {
    name  = "SERVICE_NAME"
    value = "main-application"
  }
]

# ALB Configuration for Service 1
ecs_health_check_path    = "/health"
ecs_internal_alb         = false
ecs_allowed_cidr_blocks  = ["0.0.0.0/0"]

# Certificate Configuration (use self-signed for this example)
ecs_create_self_signed_cert = true
ecs_domain_name            = "main-app.example.com"

# Security Configuration
ecs_enable_waf              = true
ecs_rate_limit_per_5min     = 2000
ecs_enable_deletion_protection = false

# Bastion Configuration
bastion_key_name                = "my-key-pair"
bastion_instance_type           = "t3.micro"
bastion_allowed_ssh_cidr_blocks = ["203.0.113.0/24"]

# Common Configuration
log_retention_in_days = 30

tags = {
  Environment   = "production"
  Project      = "dual-ecr-services"
  Service      = "main-app"
  ManagedBy    = "terraform"
  CostCenter   = "engineering"
}

# Note: For the second service (lightweight service), you would need to create
# a separate terraform configuration or modify the modules to support multiple services.
# This example shows the configuration for the main service with secrets sidecar.
# 
# To deploy the second service without secrets sidecar, you would use:
# ecs_enable_secrets_sidecar = false
# ecs_task_cpu = 256 (roughly equivalent to 200m vCPU)  
# ecs_task_memory = 200 (200MB RAM)