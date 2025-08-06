output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value = var.cloud_provider == "azure" ? (
    length(module.azure_aks) > 0 ? module.azure_aks[0].cluster_endpoint : null
  ) : (
    length(module.aws_eks) > 0 ? module.aws_eks[0].cluster_endpoint : null
  )
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value = var.cloud_provider == "azure" ? (
    length(module.azure_aks) > 0 ? module.azure_aks[0].cluster_ca_certificate : null
  ) : (
    length(module.aws_eks) > 0 ? module.aws_eks[0].cluster_ca_certificate : null
  )
  sensitive = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value = var.cloud_provider == "azure" ? (
    length(module.azure_aks) > 0 ? module.azure_aks[0].kubeconfig_command : null
  ) : (
    length(module.aws_eks) > 0 ? module.aws_eks[0].kubeconfig_command : null
  )
}