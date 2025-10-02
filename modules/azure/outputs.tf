output "cluster_id" {
  description = "The AKS cluster ID"
  value       = module.aks.cluster_id
}

output "cluster_name" {
  description = "The AKS cluster name"
  value       = module.aks.cluster_name
}

output "cluster_fqdn" {
  description = "The AKS cluster FQDN"
  value       = module.aks.cluster_fqdn
}

output "cluster_endpoint" {
  description = "The AKS cluster endpoint"
  value       = module.aks.cluster_endpoint
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes config for the cluster"
  value       = module.aks.kube_config
  sensitive   = true
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.vpc.resource_group_name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.vpc.vnet_id
}

output "aks_subnet_id" {
  description = "AKS subnet ID"
  value       = module.vpc.aks_subnet_id
}

output "identity_principal_id" {
  description = "The principal ID of the managed identity"
  value       = module.aks.identity_principal_id
}

output "identity_client_id" {
  description = "The client ID of the managed identity"
  value       = module.aks.identity_client_id
}

output "disk_encryption_set_id" {
  description = "The disk encryption set ID"
  value       = module.aks.disk_encryption_set_id
}

output "key_vault_key_id" {
  description = "The Key Vault key ID used for encryption"
  value       = module.aks.key_vault_key_id
}