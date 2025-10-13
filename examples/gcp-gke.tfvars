# GCP GKE Cluster Example Configuration
# Kubernetes version 1.32

# General Configuration
project_id = "my-project-id"
region     = "us-east1"

# VPC Configuration
create_vpc                   = true # Set to false to use existing VPC
vpc_name                     = ""   # Required if create_vpc = false
vpc_cidr                     = "10.0.0.0/16"
regions                      = ["us-east1"]
enable_private_subnets       = true
enable_public_subnets        = false
enable_nat_gateway           = true
enable_private_google_access = true
bastion_ssh_source_ranges    = ["0.0.0.0/0"]

# Bastion host configuration
bastion_subnet = ""

# Existing VPC Configuration (when create_vpc = false)
# vpc_name         = "existing-vpc"
# network_name     = "existing-vpc"
# subnetwork_name  = "existing-subnet"
# private_subnet_ids = ["projects/xxx/regions/xxx/subnetworks/xxx"]
# public_subnet_ids  = ["projects/xxx/regions/xxx/subnetworks/xxx"]

# GKE Cluster Configuration
cluster_name       = "gke-cluster"
kubernetes_version = "1.32"
release_channel    = "REGULAR" # Options: UNSPECIFIED, RAPID, REGULAR, STABLE
node_size_config   = "medium"  # Options: small, medium, large

# Network Configuration
pods_range_name        = "gke-pods"
services_range_name    = "gke-services"
master_ipv4_cidr_block = "172.16.0.0/28"

# Security Configuration
enable_binary_authorization = false
enable_shielded_nodes       = true
enable_workload_identity    = true
enable_network_policy       = true



# RBAC Configuration (optional)
rbac_group_domain   = ""
masters_group_email = ""

# Storage & CSI Drivers
enable_filestore_csi_driver = true
enable_gcs_fuse_csi_driver  = false

# Monitoring & Logging
logging_enabled_components    = ["SYSTEM_COMPONENTS", "WORKLOADS"]
monitoring_enabled_components = ["SYSTEM_COMPONENTS"]

# Autoscaling
enable_vertical_pod_autoscaling   = true
enable_horizontal_pod_autoscaling = true

# Encryption (REQUIRED)
# You must provide a KMS key resource name for GKE cluster encryption
database_encryption_key_name = "projects/my-project-id/locations/us-east1/keyRings/gke-keyring/cryptoKeys/gke-encryption-key" # Replace with your KMS key resource name

# Node Taints Configuration
# Taints for the main application node group (product workloads)
# Example: Only pods with matching tolerations can be scheduled on these nodes
main_node_taints = [
  {
    key    = "dedicated"
    value  = "product"
    effect = "NoSchedule"
  }
]
# Leave empty for no taints: main_node_taints = []

# Labels
labels = {
  environment = "production"
  managed_by  = "terraform"
  cluster     = "gke-cluster"
}
