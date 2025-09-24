# Conceptual Example: Dual ECS Services Configuration
# 
# NOTE: This is a conceptual example showing how you WOULD configure
# two services if the modules supported multiple services in one deployment.
# Currently, this requires two separate Terraform deployments.
#
# Service 1: Main application with secrets sidecar (4 vCPU, 4GB RAM, port 50001)
# Service 2: Lightweight service without sidecar (256 CPU, 200MB RAM, port 8080)

# Basic Configuration
cloud_provider = "aws"
aws_region     = "us-west-2"
cluster_name   = "multi-service-cluster"
environment    = "production"

# Module Control
enable_eks           = false
enable_ecs           = true
enable_bastion       = true
enable_nat_gateway   = true
enable_vpc_endpoints = true

# VPC Configuration
create_vpc               = true
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 3

# ============================================================================
# SERVICE 1 CONFIGURATION - Main Application with Secrets Sidecar
# ============================================================================

# Service 1: ECR Image and Resources
ecs_container_image        = "123456789012.dkr.ecr.us-west-2.amazonaws.com/main-app:latest"
ecs_container_port         = 50001
ecs_task_cpu               = 4096 # 4 vCPU
ecs_task_memory            = 4096 # 4GB RAM
ecs_desired_count          = 2
ecs_enable_secrets_sidecar = true # Enable secrets sidecar for main app

# Service 1: Secrets Configuration
ecs_secrets_prefix = "main-app/"
ecs_secrets = {
  database_url        = "postgresql://user:pass@db.internal:5432/mainapp"
  redis_url           = "redis://redis.internal:6379"
  api_key             = "sk-1234567890abcdef"
  jwt_secret          = "super-secret-jwt-signing-key"
  encryption_key      = "32-char-encryption-key-for-aes256"
  oauth_client_id     = "oauth_app_client_id"
  oauth_client_secret = "oauth_app_client_secret"
  smtp_password       = "email-service-password"
  s3_access_key       = "AKIA1234567890123456"
  s3_secret_key       = "abcdefghijklmnopqrstuvwxyz1234567890ABCD"
}

# Service 1: Environment Variables
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
  },
  {
    name  = "ENABLE_METRICS"
    value = "true"
  },
  {
    name  = "CORS_ORIGIN"
    value = "https://app.example.com"
  }
]

# Service 1: ALB and Certificate Configuration
ecs_health_check_path   = "/api/health"
ecs_internal_alb        = false
ecs_allowed_cidr_blocks = ["0.0.0.0/0"]

# Service 1: Certificate (self-signed for demo)
ecs_create_self_signed_cert = true
ecs_domain_name             = "api.example.com"

# Service 1: Security Configuration
ecs_enable_waf                 = true
ecs_rate_limit_per_5min        = 2000
ecs_enable_deletion_protection = false

# ============================================================================  
# CONCEPTUAL SERVICE 2 CONFIGURATION - Lightweight Service
# ============================================================================
# NOTE: These variables don't exist in current modules but show the concept

# Hypothetical Service 2 variables (would need to be added to modules):
# service2_container_image         = "123456789012.dkr.ecr.us-west-2.amazonaws.com/lightweight-app:latest"
# service2_container_port          = 8080
# service2_task_cpu                = 256   # ~200m vCPU equivalent
# service2_task_memory             = 200   # 200MB RAM
# service2_desired_count           = 1
# service2_enable_secrets_sidecar  = false # No secrets sidecar

# service2_environment_variables = [
#   {
#     name  = "APP_ENV"
#     value = "production"
#   },
#   {
#     name  = "LOG_LEVEL"
#     value = "warn"
#   },
#   {
#     name  = "PORT"
#     value = "8080"
#   },
#   {
#     name  = "SERVICE_NAME"
#     value = "lightweight-service"
#   }
# ]

# service2_health_check_path = "/ping"
# service2_internal_alb      = true  # Internal service
# service2_create_alb        = false # Reuse main ALB or use service mesh

# ============================================================================
# SHARED CONFIGURATION
# ============================================================================

# Bastion Configuration
bastion_key_name                = "my-key-pair"
bastion_instance_type           = "t3.micro"
bastion_allowed_ssh_cidr_blocks = ["203.0.113.0/24"]

# Common Configuration
log_retention_in_days = 30

tags = {
  Environment = "production"
  Project     = "multi-service-deployment"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}

# ============================================================================
# DEPLOYMENT INSTRUCTIONS
# ============================================================================
# 
# Since the current modules don't support multiple services, deploy as follows:
#
# 1. Main Service Deployment:
#    terraform workspace new main-service
#    terraform apply -var-file="examples/aws-ecs-dual-ecr-services.tfvars"
#
# 2. Lightweight Service Deployment:
#    terraform workspace new lightweight-service
#    terraform apply -var-file="examples/aws-ecs-lightweight-service.tfvars" \
#      -var="create_vpc=false" \
#      -var="existing_vpc_id=$(terraform output -raw vpc_id)" \
#      -var="enable_bastion=false"
#
# This approach:
# - Deploys main service with full features and secrets sidecar
# - Deploys lightweight service reusing the same VPC and bastion
# - Both services get their own ALB (could be optimized to share)
# - Services can communicate within the VPC via security group rules