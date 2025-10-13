# Main configuration for GCP infrastructure
# This module orchestrates the creation of GCP resources

# Create VPC
module "vpc" {
  source = "./vpc"
  count  = var.enable_vpc ? 1 : 0

  project_id  = var.project_id
  name_prefix = var.name_prefix != "" ? var.vpc_name : var.cluster_name
  vpc_name    = var.vpc_name
  vpc_cidr    = var.vpc_cidr
  regions     = [var.region]

  labels = var.tags
}

# Create GKE cluster
module "gke" {
  source = "./gke"
  count  = var.enable_gke ? 1 : 0

  project_id                   = var.project_id
  region                       = var.region
  cluster_name                 = var.cluster_name
  kubernetes_version           = var.kubernetes_version
  node_size_config             = var.node_size_config
  network_name                 = module.vpc[0].vpc_name
  subnetwork_name              = module.vpc[0].private_subnet_names[0]
  pods_range_name              = "pods"
  services_range_name          = "services"
  main_node_taints             = var.main_node_taints
  database_encryption_key_name = var.database_encryption_key_name

  labels = var.tags
}

# Create bastion host
module "bastion" {
  source = "./bastion"
  count  = var.create_bastion ? 1 : 0

  project_id              = var.project_id
  region                  = var.region
  cluster_name            = var.cluster_name
  zone                    = "${var.region}-a"
  subnetwork              = var.bastion_subnet != "" ? var.bastion_subnet : module.vpc[0].private_subnet_names[0]
  bastion_authorized_keys = var.bastion_authorized_keys

  labels = var.tags
}

resource "google_compute_firewall" "allow_bastion_to_gke_master" {
  count   = var.create_bastion ? 1 : 0
  project = var.project_id
  name    = "${var.name_prefix}-allow-bastion-to-gke-master"
  network = module.vpc[0].vpc_name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_tags        = ["bastion"]
  destination_ranges = [var.master_ipv4_cidr_block]
}
