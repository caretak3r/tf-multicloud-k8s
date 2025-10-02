output "resource_group_name" {
  description = "Resource group name"
  value       = var.resource_group_name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = var.create_vpc ? azurerm_resource_group.main[0].id : ""
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = var.create_vpc ? azurerm_virtual_network.main[0].id : data.azurerm_virtual_network.existing[0].id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = var.create_vpc ? azurerm_virtual_network.main[0].name : data.azurerm_virtual_network.existing[0].name
}

output "aks_subnet_id" {
  description = "AKS subnet ID"
  value       = var.create_vpc ? azurerm_subnet.aks[0].id : data.azurerm_subnet.existing[0].id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = var.create_vpc ? azurerm_subnet.private[0].id : ""
}

output "private_dns_zone_id" {
  description = "Private DNS zone ID for AKS"
  value       = var.create_vpc && var.create_private_dns_zone ? azurerm_private_dns_zone.aks[0].id : "System"
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = var.create_vpc && var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].id : null
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.create_vpc && var.enable_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "bastion_host_id" {
  description = "Bastion host ID"
  value       = var.create_vpc && var.enable_bastion ? azurerm_bastion_host.main[0].id : null
}