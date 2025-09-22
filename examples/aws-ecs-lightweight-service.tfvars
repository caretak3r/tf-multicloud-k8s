# Example: Lightweight ECS Service from ECR without Secrets Sidecar
# This example deploys a lightweight service using minimal resources
# - No secrets sidecar (secrets sidecar disabled)
# - 256 CPU units (~200m vCPU equivalent)
# - 200MB RAM

# Basic Configuration
cloud_provider = "aws"
aws_region     = "us-west-2"
cluster_name   = "lightweight-service"
environment    = "production"

# Module Control - Enable ECS only
enable_eks         = false
enable_ecs         = true
enable_bastion     = false  # No bastion needed for lightweight setup
enable_nat_gateway = true
enable_vpc_endpoints = false  # Save costs for lightweight setup

# VPC Configuration
create_vpc               = true
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2  # Minimal AZ count to save costs

# Lightweight Service Configuration
# Uses minimal CPU/memory, no secrets sidecar
ecs_container_image         = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-lightweight-app:latest"
ecs_container_port          = 8080
ecs_task_cpu                = 256   # ~200m vCPU equivalent
ecs_task_memory             = 200   # 200MB RAM
ecs_desired_count           = 1     # Single instance for lightweight
ecs_enable_secrets_sidecar  = false # No secrets sidecar

# No secrets needed for this service
ecs_secrets = {}
ecs_secrets_prefix = ""

# Simple Environment Variables (no secrets endpoint)
ecs_environment_variables = [
  {
    name  = "APP_ENV"
    value = "production"
  },
  {
    name  = "LOG_LEVEL"
    value = "warn"  # Less logging for lightweight
  },
  {
    name  = "PORT"
    value = "8080"
  },
  {
    name  = "SERVICE_NAME"
    value = "lightweight-service"
  },
  {
    name  = "ENABLE_METRICS"
    value = "false"  # Disable metrics to save resources
  }
]

# ALB Configuration
ecs_health_check_path    = "/ping"
ecs_internal_alb         = false
ecs_allowed_cidr_blocks  = ["0.0.0.0/0"]

# Skip certificate for lightweight setup (HTTP only)
ecs_create_self_signed_cert = false
ecs_domain_name            = null

# Minimal Security Configuration
ecs_enable_waf              = false  # No WAF to save costs
ecs_rate_limit_per_5min     = 1000   # Lower rate limit
ecs_enable_deletion_protection = false

# Common Configuration
log_retention_in_days = 7  # Shorter retention for lightweight

tags = {
  Environment   = "production"
  Project      = "lightweight-services"
  Service      = "lightweight-app"
  ManagedBy    = "terraform"
  CostCenter   = "engineering"
  Tier         = "lightweight"
}