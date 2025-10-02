output "cluster_id" {
  description = "GKE cluster ID"
  value       = module.gke.cluster_id
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.name
}

output "cluster_endpoint" {
  description = "Endpoint for GKE control plane"
  value       = module.gke.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public certificate for GKE cluster"
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "cluster_master_version" {
  description = "Current master version of the GKE cluster"
  value       = module.gke.master_version
}

output "cluster_region" {
  description = "GKE cluster region"
  value       = module.gke.region
}

output "cluster_zones" {
  description = "List of zones in which the cluster resides"
  value       = module.gke.zones
}

output "service_account" {
  description = "The service account used by the node pool"
  value       = module.gke.service_account
}

output "network_name" {
  description = "The name of the VPC network"
  value       = var.network_name
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = var.subnetwork_name
}

output "master_authorized_networks_config" {
  description = "Master authorized networks configuration"
  value       = module.gke.master_authorized_networks_config
}

output "node_pools_names" {
  description = "List of node pools names"
  value       = module.gke.node_pools_names
}

output "node_pools_versions" {
  description = "Node pools versions"
  value       = module.gke.node_pools_versions
}

output "cluster_identity_namespace" {
  description = "Workload Identity namespace"
  value       = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null
}

output "get_credentials_command" {
  description = "gcloud command to get cluster credentials"
  value       = "gcloud container clusters get-credentials ${module.gke.name} --region ${module.gke.region} --project ${var.project_id} --internal-ip"
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "kubectl config use-context gke_${var.project_id}_${module.gke.region}_${module.gke.name}"
}