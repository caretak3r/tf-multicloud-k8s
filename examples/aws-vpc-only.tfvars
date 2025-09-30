# Example: VPC and networking only (no EKS)
cluster_name = "my-network-foundation"
region       = "us-east-1"
environment  = "staging"

# Create VPC only
create_vpc     = true
enable_eks     = false
enable_bastion = false

# VPC Configuration
vpc_cidr                 = "10.1.0.0/16"
availability_zones_count = 3
enable_nat_gateway       = true
enable_vpc_endpoints     = true

# Common Configuration
log_retention_in_days = 30

tags = {
  Environment = "staging"
  Project     = "network-foundation"
  Owner       = "infrastructure-team"
}