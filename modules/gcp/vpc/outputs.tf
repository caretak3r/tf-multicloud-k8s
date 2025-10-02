output "vpc_id" {
  description = "The ID of the VPC"
  value       = var.create_vpc ? google_compute_network.vpc[0].id : data.google_compute_network.existing[0].id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = var.create_vpc ? google_compute_network.vpc[0].name : data.google_compute_network.existing[0].name
}

output "vpc_self_link" {
  description = "The self link of the VPC"
  value       = var.create_vpc ? google_compute_network.vpc[0].self_link : data.google_compute_network.existing[0].self_link
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = var.create_vpc && var.enable_private_subnets ? google_compute_subnetwork.private[*].id : var.private_subnet_ids
}

output "private_subnet_names" {
  description = "List of private subnet names"
  value       = var.create_vpc && var.enable_private_subnets ? google_compute_subnetwork.private[*].name : []
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = var.create_vpc && var.enable_private_subnets ? google_compute_subnetwork.private[*].ip_cidr_range : []
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = var.create_vpc && var.enable_public_subnets ? google_compute_subnetwork.public[*].id : var.public_subnet_ids
}

output "public_subnet_names" {
  description = "List of public subnet names"
  value       = var.create_vpc && var.enable_public_subnets ? google_compute_subnetwork.public[*].name : []
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = var.create_vpc && var.enable_public_subnets ? google_compute_subnetwork.public[*].ip_cidr_range : []
}

output "nat_ips" {
  description = "List of external IPs used for Cloud NAT"
  value       = var.create_vpc && var.enable_nat_gateway ? google_compute_router_nat.nat[*].nat_ips : []
}

output "regions" {
  description = "List of regions where resources are deployed"
  value       = var.regions
}