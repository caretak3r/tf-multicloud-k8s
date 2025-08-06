# Multi-Cloud Kubernetes Terraform Template

This repository provides a secure, production-ready Terraform template for deploying Kubernetes clusters on Azure AKS and AWS EKS with consistent configuration and security best practices.

## Features

- **Multi-cloud support**: Deploy to Azure AKS or AWS EKS
- **Secure by default**: RBAC, network policies, encryption, audit logging
- **Size-based configuration**: Small (dev), Medium (staging), Large (production)
- **Environment-specific configurations**: Pre-built tfvars for different environments
- **Modular design**: Separate modules for Azure and AWS

## Quick Start

1. **Copy example configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** for your environment:
   ```hcl
   cloud_provider = "azure"  # or "aws"
   cluster_name = "my-cluster"
   environment = "dev"
   node_size_config = "small"  # small, medium, or large
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure kubectl**:
   ```bash
   # For Azure
   az aks get-credentials --resource-group <rg-name> --name <cluster-name>
   
   # For AWS
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

## Size Configurations

| Size | Use Case | Node Count | Instance Type (Azure/AWS) |
|------|----------|------------|---------------------------|
| Small | Dev/Test | 2 (1-5) | Standard_DS2_v2 / t3.medium |
| Medium | Staging | 3 (2-10) | Standard_DS3_v2 / t3.large |
| Large | Production | 5 (3-20) | Standard_DS4_v2 / t3.xlarge |

## Environment Examples

Use pre-configured environment files:

```bash
# Development on Azure
terraform apply -var-file="environments/dev-azure.tfvars"

# Performance testing on AWS
terraform apply -var-file="environments/perf-aws.tfvars"

# Production on Azure
terraform apply -var-file="environments/prod-azure.tfvars"
```

## Security Features

- **RBAC**: Role-based access control enabled
- **Network Security**: Network policies and security groups
- **Encryption**: Secrets encrypted at rest (KMS/Key Vault)
- **Audit Logging**: Comprehensive cluster audit logs
- **Private Networking**: Private subnets with NAT gateways
- **Auto-scaling**: Cluster and pod auto-scaling enabled

## Directory Structure

```
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example configuration
├── size-mapping.md           # Instance size reference
├── environments/             # Pre-configured environments
│   ├── dev-azure.tfvars
│   ├── dev-aws.tfvars
│   ├── perf-azure.tfvars
│   ├── perf-aws.tfvars
│   ├── prod-azure.tfvars
│   └── prod-aws.tfvars
└── modules/
    ├── azure/               # Azure AKS module
    └── aws/                 # AWS EKS module
```

## Prerequisites

- Terraform >= 1.0
- Azure CLI (for Azure deployments)
- AWS CLI (for AWS deployments)
- kubectl

## Authentication

### Azure
```bash
az login
az account set --subscription <subscription-id>
```

### AWS
```bash
aws configure
# or use AWS_PROFILE environment variable
```

## Customization

All configurations can be customized through variables. See `variables.tf` for all available options.

## Cleanup

```bash
terraform destroy
```

**Warning**: This will delete all resources including the cluster and all workloads.