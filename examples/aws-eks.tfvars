# AWS EKS Cluster Example Configuration
# Kubernetes version 1.32

# General Configuration
region      = "us-west-2"
environment = "production"
name_prefix = "my-company"

# VPC Configuration
create_vpc              = true  # Set to false to use existing VPC
vpc_id                 = ""      # Required if create_vpc = false
vpc_cidr               = "10.0.0.0/16"
availability_zones_count = 3
enable_private_subnets = true
enable_public_subnets  = true
enable_nat_gateway     = true
enable_vpc_endpoints   = true

# Existing VPC Configuration (when create_vpc = false)
# vpc_id             = "vpc-xxxxx"
# private_subnet_ids = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
# public_subnet_ids  = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

# EKS Cluster Configuration
cluster_name       = "eks-cluster"
kubernetes_version = "1.32"
node_size_config  = "medium"  # Options: small, medium, large

# Node configuration
ami_type      = "AL2_x86_64"
capacity_type = "ON_DEMAND"  # Options: ON_DEMAND, SPOT

# Security
node_ssh_key_name = ""  # Optional: EC2 key pair name for SSH access

# Monitoring
enabled_cluster_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]
log_retention_in_days = 7

# EKS Addons (optional - leave empty for latest versions)
addon_versions = {
  vpc_cni    = null
  coredns    = null
  kube_proxy = null
  ebs_csi    = null
}

# Tags
tags = {
  Environment = "production"
  ManagedBy   = "terraform"
  Cluster     = "eks-cluster"
}