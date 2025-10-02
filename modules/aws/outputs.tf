# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = local.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = local.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = local.public_subnet_ids
}

# EKS Outputs
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = var.enable_eks ? module.eks[0].cluster_ca_certificate : null
  sensitive   = true
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = var.enable_eks ? module.eks[0].cluster_id : null
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = var.enable_eks ? module.eks[0].cluster_name : var.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = var.enable_eks ? module.eks[0].cluster_arn : null
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = var.enable_eks ? module.eks[0].cluster_version : null
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_security_group_id : null
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS worker nodes"
  value       = var.enable_eks ? module.eks[0].node_security_group_id : null
}

output "oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = var.enable_eks ? module.eks[0].oidc_issuer_url : null
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig for EKS (requires bastion or VPN access for private cluster)"
  value       = var.enable_eks ? module.eks[0].kubeconfig_command : "EKS cluster not enabled"
}

# Bastion Outputs
output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = var.enable_bastion ? module.bastion[0].bastion_instance_id : null
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].bastion_public_ip : null
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].bastion_private_ip : null
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = var.enable_bastion ? module.bastion[0].ssh_command : "Bastion host not enabled"
}

output "bastion_session_manager_command" {
  description = "AWS CLI command to connect via Session Manager"
  value       = var.enable_bastion ? module.bastion[0].session_manager_command : "Bastion host not enabled"
}


# Security Information
output "security_notes" {
  description = "Important security information about the deployment"
  value = {
    eks_private_access_only = var.enable_eks ? "EKS cluster has private endpoint access only" : "EKS not deployed"
    vpc_endpoints_enabled   = var.enable_vpc_endpoints ? "VPC endpoints enabled for private AWS API access" : "VPC endpoints disabled"
    bastion_required        = var.enable_eks && !var.enable_bastion ? "Bastion host or VPN required to access EKS cluster" : "Access configured"
    nat_gateway_enabled     = var.enable_nat_gateway ? "NAT Gateway enabled for outbound internet access" : "No outbound internet access from private subnets"
  }
}