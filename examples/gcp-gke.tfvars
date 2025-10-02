# GCP GKE Cluster Example Configuration
# Kubernetes version 1.32

# General Configuration
project_id = "my-project-id"
region     = "us-central1"

# VPC Configuration
create_vpc                   = true  # Set to false to use existing VPC
vpc_name                     = ""    # Required if create_vpc = false
vpc_cidr                    = "10.0.0.0/16"
regions                     = ["us-central1"]
enable_private_subnets      = true
enable_public_subnets       = true
enable_nat_gateway          = true
enable_private_google_access = true

# Existing VPC Configuration (when create_vpc = false)
# vpc_name         = "existing-vpc"
# network_name     = "existing-vpc"
# subnetwork_name  = "existing-subnet"
# private_subnet_ids = ["projects/xxx/regions/xxx/subnetworks/xxx"]
# public_subnet_ids  = ["projects/xxx/regions/xxx/subnetworks/xxx"]

# GKE Cluster Configuration
cluster_name       = "gke-cluster"
kubernetes_version = "1.32"
release_channel    = "REGULAR"  # Options: UNSPECIFIED, RAPID, REGULAR, STABLE
node_size_config  = "medium"    # Options: small, medium, large

# Network Configuration
pods_range_name     = "gke-pods"
services_range_name = "gke-services"
master_ipv4_cidr_block = "172.16.0.0/28"

# Security Configuration
enable_binary_authorization = false
enable_shielded_nodes      = true
enable_workload_identity   = true
enable_network_policy      = true

# Master Authorized Networks (optional)
master_authorized_networks = [
  # {
  #   cidr_block   = "0.0.0.0/0"
  #   display_name = "All networks"
  # }
]

# RBAC Configuration (optional)
rbac_group_domain   = ""
masters_group_email = ""

# Storage & CSI Drivers
enable_filestore_csi_driver = true
enable_gcs_fuse_csi_driver = false

# Monitoring & Logging
logging_enabled_components    = ["SYSTEM_COMPONENTS", "WORKLOADS"]
monitoring_enabled_components = ["SYSTEM_COMPONENTS"]

# Autoscaling
enable_vertical_pod_autoscaling   = true
enable_horizontal_pod_autoscaling = true

# Encryption (optional)
database_encryption_key_name = null  # Format: projects/PROJECT_ID/locations/LOCATION/keyRings/RING_NAME/cryptoKeys/KEY_NAME

# Labels
labels = {
  environment = "production"
  managed_by  = "terraform"
  cluster     = "gke-cluster"
}