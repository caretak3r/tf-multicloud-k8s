# Outputs for GCP infrastructure module

# VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = module.vpc.vpc_name
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "subnet_names" {
  description = "List of subnet names"
  value       = module.vpc.private_subnet_names
}

# GKE outputs
output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = module.gke.cluster_id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = module.gke.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "node_pool_names" {
  description = "The names of the GKE node pools"
  value       = module.gke.node_pools_names
}

output "region" {
  description = "The GCP region where resources are created"
  value       = var.region
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}
