
output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].cluster_endpoint : module.azure_infrastructure[0].cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].cluster_name : module.azure_infrastructure[0].cluster_name
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig for the cluster"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].kubeconfig_command : "az aks get-credentials --resource-group ${module.azure_infrastructure[0].resource_group_name} --name ${module.azure_infrastructure[0].cluster_name}"
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].bastion_ssh_command : "N/A for Azure"
}
