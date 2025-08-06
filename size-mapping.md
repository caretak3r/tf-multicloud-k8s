# Instance Size Mapping Configuration

This document describes the instance size mappings used across Azure AKS and AWS EKS deployments.

## Size Configurations

### Small (Development/Testing)
**Use case**: Development environments, testing, small workloads

| Cloud | Instance Type | Node Count | Min/Max | Disk Size | Cost Level |
|-------|---------------|------------|---------|-----------|------------|
| Azure | Standard_DS2_v2 | 2 | 1-5 | 128GB | $ |
| AWS | t3.medium | 2 | 1-5 | 20GB | $ |

**Specifications**:
- 2 vCPUs, 7GB RAM (Azure) / 2 vCPUs, 4GB RAM (AWS)
- Max pods per node: 30 (Azure) / Default (AWS)
- Auto-scaling enabled

### Medium (Staging/Pre-production)
**Use case**: Staging environments, medium workloads, performance testing

| Cloud | Instance Type | Node Count | Min/Max | Disk Size | Cost Level |
|-------|---------------|------------|---------|-----------|------------|
| Azure | Standard_DS3_v2 | 3 | 2-10 | 128GB | $$ |
| AWS | t3.large | 3 | 2-10 | 30GB | $$ |

**Specifications**:
- 4 vCPUs, 14GB RAM (Azure) / 2 vCPUs, 8GB RAM (AWS)
- Max pods per node: 50 (Azure) / Default (AWS)
- Auto-scaling enabled

### Large (Production)
**Use case**: Production environments, high-performance workloads

| Cloud | Instance Type | Node Count | Min/Max | Disk Size | Cost Level |
|-------|---------------|------------|---------|-----------|------------|
| Azure | Standard_DS4_v2 | 5 | 3-20 | 128GB | $$$ |
| AWS | t3.xlarge | 5 | 3-20 | 50GB | $$$ |

**Specifications**:
- 8 vCPUs, 28GB RAM (Azure) / 4 vCPUs, 16GB RAM (AWS)
- Max pods per node: 110 (Azure) / Default (AWS)
- Auto-scaling enabled

## Security Features

All configurations include:
- RBAC enabled
- Network policies (Azure CNI/AWS VPC CNI)
- Pod security policies
- Audit logging
- Encryption at rest
- Private endpoints (configurable)
- Monitoring and log analytics

## Usage

Set the `node_size_config` variable in your terraform.tfvars file:

```hcl
node_size_config = "small"    # or "medium" or "large"
```