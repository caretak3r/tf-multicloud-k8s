output "cluster_id" {
  description = "The AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "The AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_endpoint" {
  description = "The AKS cluster endpoint"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes config for the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "identity_principal_id" {
  description = "The principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "identity_client_id" {
  description = "The client ID of the managed identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "disk_encryption_set_id" {
  description = "The disk encryption set ID"
  value       = azurerm_disk_encryption_set.aks.id
}

output "key_vault_key_id" {
  description = "The Key Vault key ID used for encryption"
  value       = var.key_vault_key_id != null ? var.key_vault_key_id : azurerm_key_vault_key.aks[0].id
}