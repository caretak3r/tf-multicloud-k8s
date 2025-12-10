# Outputs for GKE cluster module

output "cluster_id" {
  description = "Cluster ID"
  value       = google_container_cluster.gke_cluster.id
}

output "name" {
  description = "Cluster name"
  value       = google_container_cluster.gke_cluster.name
}

output "type" {
  description = "Cluster type (regional / zonal)"
  value       = "regional"
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = google_container_cluster.gke_cluster.location
}

output "region" {
  description = "Cluster region"
  value       = var.region
}

output "zones" {
  description = "List of zones in which the cluster resides"
  value       = var.zones
}

output "endpoint" {
  sensitive   = true
  description = "Cluster endpoint"
  value       = google_container_cluster.gke_cluster.endpoint
}

output "endpoint_dns" {
  description = "Cluster endpoint DNS"
  value       = ""
}

output "min_master_version" {
  description = "Minimum master kubernetes version"
  value       = google_container_cluster.gke_cluster.min_master_version
}

output "logging_service" {
  description = "Logging service used"
  value       = google_container_cluster.gke_cluster.logging_service
}

output "monitoring_service" {
  description = "Monitoring service used"
  value       = google_container_cluster.gke_cluster.monitoring_service
}

output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted"
  value       = var.master_authorized_networks
}

output "master_version" {
  description = "Current master kubernetes version"
  value       = google_container_cluster.gke_cluster.master_version
}

output "ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)"
  value       = google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate
}

output "network_policy_enabled" {
  description = "Whether network policy enabled"
  value       = local.use_advanced_datapath ? false : true
}

output "http_load_balancing_enabled" {
  description = "Whether http load balancing enabled"
  value       = var.http_load_balancing
}

output "horizontal_pod_autoscaling_enabled" {
  description = "Whether horizontal pod autoscaling enabled"
  value       = var.horizontal_pod_autoscaling
}

output "node_pools_names" {
  description = "List of node pools names"
  value       = [google_container_node_pool.default_node_pool.name]
}

output "node_pools_versions" {
  description = "Node pool versions by node pool name"
  value = {
    (google_container_node_pool.default_node_pool.name) = google_container_node_pool.default_node_pool.version
  }
}

output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = local.service_account_email
}

output "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the hosted master network"
  value       = var.master_ipv4_cidr_block
}

output "peering_name" {
  description = "The name of the peering between this cluster and the Google owned VPC."
  value       = ""
}

output "enable_mesh_certificates" {
  description = "Mesh certificate configuration value"
  value       = var.enable_mesh_certificates
}
