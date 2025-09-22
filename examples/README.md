# Terraform Configuration Examples

This directory contains example `terraform.tfvars` files demonstrating various deployment scenarios for the multicloud Terraform project.

## ECS Examples

### Basic ECS Deployments

- **`aws-ecs-full-stack.tfvars`** - Complete ECS deployment with all features
- **`aws-ecs-only.tfvars`** - ECS-only deployment without EKS
- **`aws-ecs-production-ready.tfvars`** - 🆕 Production-ready ECS with secrets sidecar, 4 vCPU/4GB RAM, port 50001

### ECR-Based Deployments

- **`aws-ecs-dual-ecr-services.tfvars`** - 🆕 Main application service from ECR with secrets sidecar
- **`aws-ecs-lightweight-service.tfvars`** - 🆕 Lightweight service (256 CPU/200MB RAM) without secrets sidecar
- **`aws-ecs-dual-service-concept.tfvars`** - 🆕 Conceptual example showing dual-service configuration

### Multi-Service Setup

- **`aws-ecs-multi-service-setup.md`** - 🆕 Guide for deploying multiple ECS services

## EKS Examples

- **`aws-eks-only.tfvars`** - EKS-only deployment without ECS

## Infrastructure Examples

- **`aws-full-stack.tfvars`** - Complete AWS deployment with both EKS and ECS
- **`aws-vpc-only.tfvars`** - VPC-only deployment for shared infrastructure

## New Features Highlighted

### Secrets Sidecar Control

All ECS examples now support the `ecs_enable_secrets_sidecar` variable:

```hcl
# Enable secrets sidecar (default)
ecs_enable_secrets_sidecar = true

# Disable secrets sidecar for lightweight services
ecs_enable_secrets_sidecar = false
```

### When to Use Secrets Sidecar

**Enable secrets sidecar when:**
- Application needs secure access to database credentials, API keys, certificates
- Secrets require rotation without container restart
- Application benefits from centralized secret management
- Security compliance requires encrypted secret access

**Disable secrets sidecar when:**
- Lightweight services with minimal resource requirements
- Applications don't use secrets (or use environment variables only)
- Cost optimization is prioritized over advanced secret management

## Resource Configurations

### Production Service (with secrets sidecar)
```hcl
ecs_task_cpu                = 4096  # 4 vCPU
ecs_task_memory             = 4096  # 4GB RAM
ecs_container_port          = 50001
ecs_enable_secrets_sidecar  = true
```

### Lightweight Service (without secrets sidecar)
```hcl
ecs_task_cpu                = 256   # ~200m vCPU equivalent
ecs_task_memory             = 200   # 200MB RAM
ecs_container_port          = 8080
ecs_enable_secrets_sidecar  = false
```

## Terraform Variable Files (tfvars) Reference

This section provides detailed information about all available `.tfvars` example files and their configurations.

### Core Infrastructure Examples

#### **`aws-full-stack.tfvars`**
Complete AWS deployment with both EKS and ECS components.

**Key Variables:**
```hcl
cluster_name  = "my-secure-eks"
region        = "us-west-2"
environment   = "dev"
create_vpc    = true
enable_eks    = true
enable_bastion = true

# VPC Configuration
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2
enable_nat_gateway       = true
enable_vpc_endpoints     = true

# EKS Configuration
node_size_config    = "medium"
kubernetes_version  = "1.28"
capacity_type      = "ON_DEMAND"
node_ssh_key_name  = "my-keypair"

# Bastion Configuration
bastion_key_name                = "my-keypair"
bastion_instance_type           = "t3.micro"
bastion_allowed_ssh_cidr_blocks = ["203.0.113.0/24"]
```

#### **`aws-vpc-only.tfvars`**
VPC-only deployment for shared infrastructure.

**Key Variables:**
```hcl
create_vpc    = true
enable_eks    = false
enable_ecs    = false
enable_bastion = false
vpc_cidr      = "10.0.0.0/16"
```

### ECS Deployment Examples

#### **`aws-ecs-production-ready.tfvars`**
Production-ready ECS with secrets sidecar, 4 vCPU/4GB RAM, port 50001.

**Key Variables:**
```hcl
ecs_container_image         = "123456789012.dkr.ecr.us-west-2.amazonaws.com/production-app:v1.2.3"
ecs_container_port          = 50001
ecs_task_cpu                = 4096  # 4 vCPU
ecs_task_memory             = 4096  # 4GB RAM
ecs_desired_count           = 3
ecs_enable_secrets_sidecar  = true

# Comprehensive secrets configuration
ecs_secrets = {
  database_url            = "postgresql://..."
  stripe_secret_key       = "sk_live_..."
  jwt_signing_key         = "HS256-..."
  # ... and many more production secrets
}

# SSL Certificate
ecs_acm_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/..."

# Production security
ecs_enable_waf              = true
ecs_rate_limit_per_5min     = 5000
ecs_enable_deletion_protection = true
```

#### **`aws-ecs-lightweight-service.tfvars`**
Lightweight service (256 CPU/200MB RAM) without secrets sidecar.

**Key Variables:**
```hcl
ecs_container_image         = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-lightweight-app:latest"
ecs_container_port          = 8080
ecs_task_cpu                = 256   # ~200m vCPU equivalent
ecs_task_memory             = 200   # 200MB RAM
ecs_desired_count           = 1
ecs_enable_secrets_sidecar  = false # No secrets sidecar

# Cost optimization
enable_bastion           = false
enable_vpc_endpoints     = false
ecs_enable_waf          = false
availability_zones_count = 2
```

#### **`aws-ecs-dual-ecr-services.tfvars`**
Main application service from ECR with secrets sidecar.

**Key Variables:**
```hcl
ecs_container_image         = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-main-app:latest"
ecs_container_port          = 50001
ecs_task_cpu                = 4096  # 4 vCPU
ecs_task_memory             = 4096  # 4GB RAM
ecs_enable_secrets_sidecar  = true

# Self-signed certificate for development
ecs_create_self_signed_cert = true
ecs_domain_name            = "main-app.example.com"
```

#### **`aws-ecs-full-stack.tfvars`**
Complete ECS deployment with all features enabled.

**Key Variables:**
```hcl
enable_ecs         = true
enable_bastion     = true
enable_nat_gateway = true
enable_vpc_endpoints = true
ecs_enable_secrets_sidecar = true
```

#### **`aws-ecs-only.tfvars`**
ECS-only deployment without EKS.

**Key Variables:**
```hcl
enable_eks = false
enable_ecs = true
```

### Specialized ECS Examples

#### **`ecs-http-secrets-example.tfvars`**
HTTP server with secrets sidecar demonstration.

**Key Variables:**
```hcl
ecs_container_image = "nginx:latest"
ecs_container_port  = 443  # HTTPS port
ecs_task_cpu        = 512
ecs_task_memory     = 1024
ecs_enable_secrets_sidecar = true

# Development-focused configuration
ecs_create_self_signed_cert = true
ecs_domain_name            = "http-server.example.local"

# Environment variables for HTTPS
ecs_environment_variables = [
  { name = "ENABLE_HTTPS", value = "true" },
  { name = "CERT_PATH", value = "/etc/ssl/certs/server.crt" },
  { name = "SECRETS_SIDECAR_URL", value = "http://localhost:8080" }
]
```

#### **`aws-ecs-secure-deployment.tfvars`**
Secure ECS deployment with existing VPC and comprehensive TLS configuration.

**Key Variables:**
```hcl
# Use existing VPC
create_vpc = false
existing_vpc_id = "vpc-0123456789abcdef0"
existing_private_subnet_ids = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
existing_public_subnet_ids = ["subnet-0abcdef0123456789", "subnet-09876543210fedcba"]

# Service configuration
ecs_container_port = 50051
ecs_task_cpu       = 2048  # 2 vCPU
ecs_task_memory    = 4096  # 4GB RAM

# Comprehensive secrets with TLS certificates
ecs_secrets = {
  product_client_id    = "/secure-app/prod/product_client_id"
  platform_client_id   = "/secure-app/prod/platform_client_id"
  ssl_certificate      = "/secure-app/prod/ssl_certificate"
  ssl_private_key     = "/secure-app/prod/ssl_private_key"
}

# ACM certificate for production
ecs_acm_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/your-cert-id"
```

#### **`aws-ecs-dual-service-concept.tfvars`**
Conceptual example showing dual-service configuration approach.

### EKS Examples

#### **`aws-eks-only.tfvars`**
EKS-only deployment without ECS.

**Key Variables:**
```hcl
enable_eks = true
enable_ecs = false
node_size_config    = "medium"
kubernetes_version  = "1.28"
capacity_type      = "ON_DEMAND"
```

## Usage Examples

### Single Service Deployment
```bash
terraform apply -var-file="examples/aws-ecs-production-ready.tfvars"
```

### Multi-Service Deployment
```bash
# Deploy main service
terraform workspace new main-service
terraform apply -var-file="examples/aws-ecs-dual-ecr-services.tfvars"

# Deploy lightweight service (reusing VPC)
terraform workspace new lightweight-service
MAIN_VPC_ID=$(terraform workspace select main-service && terraform output -raw vpc_id)
terraform workspace select lightweight-service
terraform apply -var-file="examples/aws-ecs-lightweight-service.tfvars" \
  -var="create_vpc=false" \
  -var="existing_vpc_id=${MAIN_VPC_ID}" \
  -var="enable_bastion=false"
```

### Secure Deployment with Helper Scripts
```bash
# Setup secure deployment
./examples/create-keypair.sh
./examples/generate-certs.sh
./examples/upload-secrets.sh
terraform apply -var-file="examples/aws-ecs-secure-deployment.tfvars"
```

## Environment-Specific Configurations

The `environments/` directory contains environment-specific variable files:
- `dev-aws.tfvars`, `dev-azure.tfvars` - Development environments
- `perf-aws.tfvars`, `perf-azure.tfvars` - Performance testing environments  
- `prod-aws.tfvars`, `prod-azure.tfvars` - Production environments

## Secrets Sidecar Usage

When `ecs_enable_secrets_sidecar = true`, your application can access secrets via HTTP:

```bash
# Get individual secret
curl http://localhost:8080/secrets/database_url

# Get all secrets as JSON
curl http://localhost:8080/secrets

# Health check
curl http://localhost:8080/health
```

The sidecar provides:
- Secure AWS Secrets Manager integration
- Automatic secret rotation support
- In-memory caching with TTL
- Health monitoring and retries

## Next Steps

1. Copy an appropriate example file to `terraform.tfvars`
2. Modify the configuration for your specific requirements
3. Update container images to point to your ECR repositories
4. Configure secrets according to your application needs
5. Run `terraform plan` to review changes before applying