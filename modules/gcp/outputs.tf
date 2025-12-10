# Outputs for GCP infrastructure module

# VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = var.enable_vpc ? module.vpc[0].vpc_id : null
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = var.enable_vpc ? module.vpc[0].vpc_name : var.vpc_name
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = var.enable_vpc ? module.vpc[0].private_subnet_ids : []
}

output "subnet_names" {
  description = "List of subnet names"
  value       = var.enable_vpc ? module.vpc[0].private_subnet_names : []
}

# GKE outputs
output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = var.enable_gke ? module.gke[0].cluster_id : null
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = var.enable_gke ? module.gke[0].name : null
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  sensitive   = true
  value       = var.enable_gke ? module.gke[0].endpoint : null
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  sensitive   = true
  value       = var.enable_gke ? module.gke[0].ca_certificate : null
}

output "node_pool_names" {
  description = "The names of the GKE node pools"
  value       = var.enable_gke ? module.gke[0].node_pools_names : []
}

output "region" {
  description = "The GCP region where resources are created"
  value       = var.region
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}
