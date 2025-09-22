# Multi-Service ECS Setup Example

This document explains how to deploy multiple ECS services with different configurations using this Terraform project.

## Current Architecture Limitation

The current Terraform modules support **one ECS service per deployment**. To deploy multiple services, you need to create separate Terraform configurations or workspaces.

## Recommended Approach

### Option 1: Separate Terraform Workspaces

Deploy each service in its own workspace:

```bash
# Deploy main service with secrets sidecar
terraform workspace new main-service
terraform apply -var-file="examples/aws-ecs-dual-ecr-services.tfvars"

# Deploy lightweight service without secrets sidecar  
terraform workspace new lightweight-service
terraform apply -var-file="examples/aws-ecs-lightweight-service.tfvars"
```

### Option 2: Separate Directories

Create separate directories for each service:

```
infrastructure/
├── main-service/
│   ├── main.tf -> symlink to ../../main.tf
│   ├── variables.tf -> symlink to ../../variables.tf
│   └── terraform.tfvars (main service config)
└── lightweight-service/
    ├── main.tf -> symlink to ../../main.tf
    ├── variables.tf -> symlink to ../../variables.tf
    └── terraform.tfvars (lightweight service config)
```

## Service Configuration Examples

### Main Service (with secrets sidecar)
- **Resources**: 4 vCPU, 4GB RAM
- **Port**: 50001
- **Features**: Secrets sidecar, certificates, WAF protection
- **Use case**: Main application requiring secure access to secrets and certificates

See: `aws-ecs-dual-ecr-services.tfvars`

### Lightweight Service (no secrets sidecar)
- **Resources**: 256 CPU units (~200m vCPU), 200MB RAM  
- **Port**: 8080
- **Features**: Minimal setup, no secrets sidecar, cost-optimized
- **Use case**: Simple API or microservice without secret requirements

See: `aws-ecs-lightweight-service.tfvars`

## Shared Infrastructure

When deploying multiple services, consider sharing:

1. **VPC**: Use `create_vpc = false` and `existing_vpc_id` for additional services
2. **Bastion Host**: Deploy once and reference from multiple services
3. **Load Balancer**: Current architecture creates one ALB per service

## Example Deployment Sequence

```bash
# 1. Deploy main service (creates VPC, bastion, etc.)
terraform workspace new main-service
terraform apply -var-file="examples/aws-ecs-dual-ecr-services.tfvars"

# 2. Get VPC ID from main service
MAIN_VPC_ID=$(terraform output vpc_id)

# 3. Deploy lightweight service using existing VPC
terraform workspace new lightweight-service
terraform apply -var-file="examples/aws-ecs-lightweight-service.tfvars" \
  -var="create_vpc=false" \
  -var="existing_vpc_id=${MAIN_VPC_ID}" \
  -var="enable_bastion=false"  # Reuse bastion from main service
```

## Service Communication

If services need to communicate:

1. **Internal ALB**: Set `ecs_internal_alb = true` for internal services
2. **Security Groups**: Services in the same VPC can communicate via security group rules
3. **Service Discovery**: Consider AWS Cloud Map for service discovery

## Secrets Management

- **With Sidecar**: Set `ecs_enable_secrets_sidecar = true`
  - Secrets accessed via HTTP endpoint (`http://localhost:8080`)
  - Automatic certificate management
  - Secure secret rotation support

- **Without Sidecar**: Set `ecs_enable_secrets_sidecar = false`
  - Direct environment variables only
  - No automatic secret rotation
  - Reduced resource usage and complexity