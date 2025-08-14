# AWS Infrastructure Modules

This directory contains modular Terraform configurations for deploying secure AWS infrastructure with EKS, VPC, and optional bastion host.

## Architecture Overview

The modules provide a highly secure, private-by-default AWS infrastructure:

- **VPC Module**: Creates a VPC with private/public subnets, NAT gateways, and VPC endpoints
- **EKS Module**: Deploys a private EKS cluster with worker nodes in private subnets
- **Bastion Module**: Optional bastion host for secure access to private resources

## Key Security Features

### Private-by-Default
- EKS cluster has **private endpoint access only** (no public access)
- Worker nodes deployed in private subnets only
- No `0.0.0.0/0` access in security groups (except for necessary outbound traffic)

### VPC Endpoints
- Private endpoints for ECR, EKS, CloudWatch, EC2, STS, and S3
- Eliminates need for internet access to AWS APIs
- Reduces data transfer costs and improves security

### Network Security
- Restrictive security groups with principle of least privilege
- Bastion host with controlled SSH access from specific CIDR blocks
- Encrypted EBS volumes and KMS encryption for EKS secrets

## Module Structure

```
modules/aws/
├── main.tf           # Orchestrates all sub-modules
├── variables.tf      # Input variables with validation
├── outputs.tf        # Module outputs
├── vpc/             # VPC and networking resources
├── eks/             # EKS cluster and node groups
└── bastion/         # Optional bastion host
```

## Usage Examples

### 1. Full Stack (VPC + EKS + Bastion)
```hcl
module "aws_infrastructure" {
  source = "./modules/aws"
  
  cluster_name  = "my-secure-eks"
  region        = "us-west-2"
  environment   = "production"
  
  # Enable all components
  create_vpc     = true
  enable_eks     = true
  enable_bastion = true
  
  # Bastion configuration
  bastion_key_name                = "my-keypair"
  bastion_allowed_ssh_cidr_blocks = ["203.0.113.0/24"]
  
  # EKS configuration
  node_size_config = "medium"
  node_ssh_key_name = "my-keypair"
  
  tags = {
    Environment = "production"
    Project     = "secure-platform"
  }
}
```

### 2. EKS Only (Existing VPC)
```hcl
module "aws_infrastructure" {
  source = "./modules/aws"
  
  cluster_name    = "my-eks"
  region          = "us-west-2"
  environment     = "production"
  
  # Use existing VPC
  create_vpc      = false
  existing_vpc_id = "vpc-0123456789abcdef0"
  
  # Enable only EKS
  enable_eks     = true
  enable_bastion = false
  
  node_size_config = "large"
}
```

### 3. VPC Only (Network Foundation)
```hcl
module "aws_infrastructure" {
  source = "./modules/aws"
  
  cluster_name = "network-foundation"
  region       = "us-west-2"
  environment  = "shared"
  
  # Create VPC only
  create_vpc     = true
  enable_eks     = false
  enable_bastion = false
  
  vpc_cidr                 = "10.0.0.0/16"
  availability_zones_count = 3
}
```

## Variables

### Module Control
- `create_vpc`: Whether to create a new VPC (default: true)
- `existing_vpc_id`: ID of existing VPC (required if create_vpc is false)
- `enable_eks`: Whether to create EKS cluster (default: true)
- `enable_bastion`: Whether to create bastion host (default: false)
- `enable_nat_gateway`: Whether to create NAT gateways (default: true)
- `enable_vpc_endpoints`: Whether to create VPC endpoints (default: true)

### VPC Configuration
- `vpc_cidr`: CIDR block for VPC (default: "10.0.0.0/16")
- `availability_zones_count`: Number of AZs to use (default: 2, max: 6)

### EKS Configuration
- `node_size_config`: Node size (small/medium/large, default: small)
- `kubernetes_version`: EKS version (default: "1.28")
- `capacity_type`: ON_DEMAND or SPOT (default: ON_DEMAND)
- `node_ssh_key_name`: EC2 key pair for worker nodes

### Bastion Configuration
- `bastion_key_name`: EC2 key pair for bastion host
- `bastion_allowed_ssh_cidr_blocks`: CIDR blocks allowed SSH access
- `bastion_instance_type`: Instance type (default: t3.micro)

## Outputs

### VPC Outputs
- `vpc_id`: VPC ID
- `private_subnet_ids`: Private subnet IDs
- `public_subnet_ids`: Public subnet IDs

### EKS Outputs
- `cluster_endpoint`: EKS cluster endpoint
- `cluster_name`: EKS cluster name
- `kubeconfig_command`: Command to configure kubectl

### Bastion Outputs
- `bastion_public_ip`: Bastion host public IP
- `bastion_ssh_command`: SSH command to connect to bastion
- `bastion_session_manager_command`: AWS Session Manager command

### Security Information
- `security_notes`: Important security information about deployment

## Accessing the EKS Cluster

Since the EKS cluster is private-only, you have several options for access:

### Option 1: Bastion Host
1. Enable bastion host: `enable_bastion = true`
2. SSH to bastion: Use output `bastion_ssh_command`
3. Run kubectl from bastion: `./eks-connect.sh`

### Option 2: AWS Session Manager
1. Use output `bastion_session_manager_command`
2. No SSH keys required, uses IAM for authentication

### Option 3: VPN/Direct Connect
1. Set up VPN or Direct Connect to VPC
2. Configure kubectl locally
3. Access cluster directly through private connection

## Security Best Practices

1. **Always use specific CIDR blocks** for bastion SSH access, never `0.0.0.0/0`
2. **Rotate SSH keys regularly** and store them securely
3. **Use AWS Session Manager** instead of SSH when possible
4. **Enable VPC Flow Logs** for network monitoring
5. **Regularly update EKS version** and worker node AMIs
6. **Use IAM roles for service accounts (IRSA)** for pod-level permissions
7. **Enable AWS Config** and **CloudTrail** for compliance monitoring

## Cost Optimization

- Use SPOT instances for non-production workloads (`capacity_type = "SPOT"`)
- Adjust `node_size_config` based on workload requirements
- Consider disabling NAT Gateway if no outbound internet access needed
- Use smaller bastion instance types (`t3.nano` for basic access)

## Troubleshooting

### Common Issues

1. **Cannot access EKS cluster**
   - Ensure bastion host is deployed or VPN is configured
   - Check security group rules
   - Verify kubectl configuration

2. **Worker nodes not joining cluster**
   - Check subnet routing to NAT Gateway
   - Verify VPC endpoints are working
   - Check IAM roles and policies

3. **Bastion host cannot SSH to worker nodes**
   - Ensure `node_ssh_key_name` is set
   - Check security group allows SSH from bastion

4. **High data transfer costs**
   - Ensure VPC endpoints are enabled
   - Check traffic patterns and routing