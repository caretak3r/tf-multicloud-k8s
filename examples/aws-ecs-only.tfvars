# Minimal ECS Configuration using existing VPC
region       = "us-west-2"
cluster_name = "simple-ecs"
environment  = "dev"

# Module Control - Only ECS, use existing VPC
enable_eks           = false
enable_ecs           = true
enable_bastion       = false
enable_nat_gateway   = false
enable_vpc_endpoints = false

# Use Existing VPC
create_vpc      = false
existing_vpc_id = "vpc-0123456789abcdef0"

# ECS Configuration
ecs_container_image = "nginx:latest"
ecs_container_port  = 80
ecs_task_cpu        = 256
ecs_task_memory     = 512
ecs_desired_count   = 1

# Simple secrets configuration
ecs_secrets_prefix = "simple-app/"
ecs_secrets = {
  app_secret = "my-secret-value"
}

# Use self-signed certificate
ecs_create_self_signed_cert = true

# Basic ALB settings
ecs_health_check_path = "/"
ecs_internal_alb      = false

# Security - disable WAF for simplicity
ecs_enable_waf = false

tags = {
  Environment = "dev"
  Project     = "simple-ecs"
}