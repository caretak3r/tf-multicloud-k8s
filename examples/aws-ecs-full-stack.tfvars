# Basic Configuration
region       = "us-west-2"
cluster_name = "my-ecs-app"
environment  = "production"

# Module Control - Enable ECS and disable EKS
enable_eks           = false
enable_ecs           = true
enable_bastion       = true
enable_nat_gateway   = true
enable_vpc_endpoints = true

# VPC Configuration
create_vpc               = true
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 3

# ECS Container Configuration
ecs_container_image = "my-app:latest"
ecs_container_port  = 8000
ecs_task_cpu        = 1024
ecs_task_memory     = 2048
ecs_desired_count   = 3

# Secrets Configuration
ecs_secrets_prefix = "myapp/"
ecs_secrets = {
  database_url   = "postgresql://user:pass@db:5432/myapp"
  api_key        = "your-secret-api-key"
  encryption_key = "your-encryption-key"
}

# Environment Variables
ecs_environment_variables = [
  {
    name  = "APP_ENV"
    value = "production"
  },
  {
    name  = "LOG_LEVEL"
    value = "info"
  }
]

# ALB Configuration
ecs_health_check_path   = "/health"
ecs_internal_alb        = false
ecs_allowed_cidr_blocks = ["0.0.0.0/0"]

# Certificate Configuration (use existing certificate)
# ecs_acm_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# OR create self-signed certificate (default behavior)
ecs_create_self_signed_cert = true
ecs_domain_name             = "myapp.example.com"

# Security Configuration
ecs_enable_waf                 = true
ecs_rate_limit_per_5min        = 2000
ecs_enable_deletion_protection = false

# Bastion Configuration
bastion_key_name                = "my-key-pair"
bastion_instance_type           = "t3.micro"
bastion_allowed_ssh_cidr_blocks = ["203.0.113.0/24"]

# Common Configuration
log_retention_in_days = 30

tags = {
  Environment = "production"
  Project     = "my-ecs-app"
  ManagedBy   = "terraform"
}