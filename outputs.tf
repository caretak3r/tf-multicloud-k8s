# EKS/AKS Outputs (for Kubernetes clusters)
output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value = var.cloud_provider == "azure" ? (
    length(module.azure_aks) > 0 ? module.azure_aks[0].cluster_endpoint : null
    ) : (
    var.enable_eks && length(module.aws_infrastructure) > 0 ? module.aws_infrastructure[0].cluster_endpoint : null
  )
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value = var.cloud_provider == "azure" ? (
    length(module.azure_aks) > 0 ? module.azure_aks[0].cluster_ca_certificate : null
    ) : (
    var.enable_eks && length(module.aws_infrastructure) > 0 ? module.aws_infrastructure[0].cluster_ca_certificate : null
  )
  sensitive = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value = var.cloud_provider == "azure" ? (
    length(module.azure_aks) > 0 ? module.azure_aks[0].kubeconfig_command : null
    ) : (
    var.enable_eks && length(module.aws_infrastructure) > 0 ? module.aws_infrastructure[0].kubeconfig_command : null
  )
}

# ECS Outputs (for container services)
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.cloud_provider == "aws" && var.enable_ecs && length(module.aws_infrastructure) > 0 ? module.aws_infrastructure[0].ecs_cluster_name : null
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = var.cloud_provider == "aws" && var.enable_ecs && length(module.aws_infrastructure) > 0 ? module.aws_infrastructure[0].ecs_service_name : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.cloud_provider == "aws" && var.enable_ecs && length(module.aws_infrastructure) > 0 ? module.aws_infrastructure[0].alb_dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = var.cloud_provider == "aws" && var.enable_ecs && length(module.aws_infrastructure) > 0 ? module.aws_infrastructure[0].alb_zone_id : null
}