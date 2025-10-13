# Example variables for the GCP module.
#
# When using this module as a standalone component, you would typically create a
# `main.tf` file in this directory to call the `vpc` and `gke` sub-modules.
# This file provides example variables for that purpose.
#
# You can copy this file to `terraform.tfvars` and edit the values.

# --- General ---

# IMPORTANT: You must replace this with your actual GCP Project ID.
project_id = "sodium-hour-474721-r0"

# The GCP region to deploy resources in.
region = "us-east1"

# A prefix used for naming resources, like the VPC network.
name_prefix = "tf-gke"

# --- Networking (VPC Module) ---

# Create a VPC
enable_vpc = true

# The name for the VPC
vpc_name = "tf-gke"

# Create private subnets
enable_private_subnets = true

# --- GKE Cluster (GKE Module) ---

# A name for the GKE cluster.
cluster_name = "tf-gke-cluster"

# The size of the worker nodes. Options: "small", "medium", "large".
node_size_config = "medium"

# The Kubernetes version for the GKE cluster.
kubernetes_version = "1.32"

# The database_encryption_key_name must be a valid GCP KMS key resource name in the format:
# projects/PROJECT_ID/locations/LOCATION/keyRings/RING_NAME/cryptoKeys/KEY_NAME.
database_encryption_key_name = "projects/sodium-hour-474721-r0/locations/us-east1/keyRings/default/cryptoKeys/gke"


# --- Bastion Host (Instance Module) ---

# Create a bastion host
create_bastion = true

# Set your public key to authorized_keys
bastion_authorized_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyE4AHbhD9dHDjzXL0UJ5NQqs/2pcOOc3NbMcMqjil/ rohit@rohits-MacBook-Pro.local"]


# --- Labels ---

# Custom labels to apply to all resources.
labels = {
  Environment = "dev"
  Project     = "kubernetes-cluster"
  Team        = "devops"
  Owner       = "your-team@company.com"
}
