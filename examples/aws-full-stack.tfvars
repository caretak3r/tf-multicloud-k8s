# Example: Full AWS stack with VPC, EKS, and Bastion
cluster_name  = "my-secure-eks"
region        = "us-west-2"
environment   = "dev"

# Enable all components
create_vpc      = true
enable_eks      = true
enable_bastion  = true

# VPC Configuration
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2
enable_nat_gateway       = true
enable_vpc_endpoints     = true

# EKS Configuration
node_size_config         = "medium"
kubernetes_version       = "1.28"
capacity_type           = "ON_DEMAND"
node_ssh_key_name       = "my-keypair"

# Bastion Configuration
bastion_key_name                = "my-keypair"
bastion_instance_type           = "t3.micro"
bastion_allowed_ssh_cidr_blocks = ["203.0.113.0/24"]  # Replace with your IP

# Common Configuration
log_retention_in_days = 14

tags = {
  Environment = "dev"
  Project     = "secure-eks"
  Owner       = "platform-team"
}