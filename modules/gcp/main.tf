# Main configuration for GCP infrastructure
# This module orchestrates the creation of GCP resources

# Create VPC
module "vpc" {
  source = "./vpc"
  count  = var.enable_vpc ? 1 : 0

  project_id                   = var.project_id
  name_prefix                  = var.name_prefix
  vpc_name                     = var.vpc_name
  vpc_cidr                     = var.vpc_cidr
  regions                      = var.regions
  enable_private_subnets       = var.enable_private_subnets
  enable_public_subnets        = var.enable_public_subnets
  enable_nat_gateway           = var.enable_nat_gateway
  enable_private_google_access = var.enable_private_google_access
  bastion_ssh_source_ranges    = var.bastion_ssh_source_ranges

  labels = var.tags
}

# Create GKE cluster
module "gke" {
  source = "./gke"
  count  = var.enable_gke ? 1 : 0

  project_id         = var.project_id
  region             = var.region
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version
  network            = var.enable_vpc ? module.vpc[0].vpc_name : var.vpc_name
  subnetwork         = var.enable_vpc ? module.vpc[0].private_subnet_names[0] : var.subnetwork

  # IP ranges - conditional based on whether we're creating VPC or using existing
  ip_range_pods     = var.enable_vpc ? var.pods_range_name : var.existing_pods_range
  ip_range_services = var.enable_vpc ? var.services_range_name : var.existing_services_range

  # Cluster settings
  master_ipv4_cidr_block          = var.master_ipv4_cidr_block
  enable_private_endpoint         = true
  enable_shielded_nodes           = var.enable_shielded_nodes
  enable_vertical_pod_autoscaling = var.enable_vertical_pod_autoscaling
  release_channel                 = var.release_channel
  filestore_csi_driver            = var.enable_filestore_csi_driver
  gcs_fuse_csi_driver             = var.enable_gcs_fuse_csi_driver
  monitoring_enabled_components   = var.monitoring_enabled_components

  # Database encryption
  database_encryption = [{
    state    = length(var.database_encryption_key_name) > 0 ? "ENCRYPTED" : "DECRYPTED"
    key_name = var.database_encryption_key_name
  }]

  cluster_resource_labels = var.tags
}

# Create bastion host
module "bastion" {
  source = "./bastion"
  count  = var.create_bastion ? 1 : 0

  project_id              = var.project_id
  region                  = var.region
  cluster_name            = var.cluster_name
  zone                    = "${var.region}-a"
  subnetwork              = var.bastion_subnet != "" ? var.bastion_subnet : (var.enable_vpc ? module.vpc[0].private_subnet_names[0] : var.subnetwork)
  bastion_authorized_keys = var.bastion_authorized_keys

  labels = var.tags
}

# Firewall rule for bastion to access GKE master
# Only created when bastion is enabled AND GKE is enabled
resource "google_compute_firewall" "allow_bastion_to_gke_master" {
  count   = var.create_bastion && var.enable_gke ? 1 : 0
  project = var.project_id
  name    = "${var.name_prefix}-allow-bastion-to-gke-master"
  network = var.enable_vpc ? module.vpc[0].vpc_name : var.vpc_name

  allow {
    protocol = "tcp"
    ports    = var.gke_master_to_nodes_ports
  }

  source_tags        = ["bastion"]
  destination_ranges = [var.master_ipv4_cidr_block]
}
