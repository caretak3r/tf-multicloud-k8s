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