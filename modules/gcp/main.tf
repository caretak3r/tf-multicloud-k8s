# Main configuration for GCP infrastructure
# This module orchestrates the creation of GCP resources

# Create VPC
module "vpc" {
  source = "./vpc"

  name_prefix = var.vpc_name != "" ? var.vpc_name : var.cluster_name
  vpc_name    = var.vpc_name
  vpc_cidr    = var.vpc_cidr
  regions     = [var.region]

  labels = var.common_tags
}

# Create GKE cluster
module "gke" {
  source = "./gke"

  project_id          = var.project_id
  region              = var.region
  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  node_size_config    = var.node_size_config
  network_name        = module.vpc.vpc_name
  subnetwork_name     = module.vpc.private_subnet_names[0]
  pods_range_name     = "pods"
  services_range_name = "services"
  main_node_taints    = var.main_node_taints

  labels = var.common_tags
}
