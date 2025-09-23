# Example: EKS cluster only (using existing VPC)
cluster_name  = "my-eks-existing-vpc"
region        = "us-west-2"
environment   = "prod"

# Use existing VPC
create_vpc        = false
existing_vpc_id   = "vpc-0123456789abcdef0"  # Replace with your VPC ID

# Enable only EKS, disable ECS explicitly
enable_eks     = true
enable_ecs     = false
enable_bastion = false

# Networking
enable_nat_gateway   = false  # Assuming existing VPC has NAT
enable_vpc_endpoints = true

# EKS Configuration
node_size_config   = "large"
kubernetes_version = "1.28"
capacity_type     = "SPOT"

# Common Configuration
log_retention_in_days = 7

tags = {
  Environment = "prod"
  Project     = "microservices"
  Owner       = "devops-team"
}