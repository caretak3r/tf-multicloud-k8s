terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# VPC/Network module
module "vpc" {
  source = "./vpc"

  resource_group_name = var.resource_group_name
  location           = var.location
  name_prefix        = var.cluster_name
  create_vpc         = var.create_vpc
  vpc_id             = var.vpc_id
  subnet_id          = var.subnet_id
  vnet_cidr          = var.vnet_cidr
  aks_subnet_cidr    = var.aks_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  bastion_subnet_cidr = var.bastion_subnet_cidr
  enable_nat_gateway  = var.enable_nat_gateway
  enable_bastion      = var.enable_bastion
  create_private_dns_zone = var.create_private_dns_zone
  enable_log_analytics = var.enable_log_analytics
  log_retention_days   = var.log_retention_days
  tags                 = var.tags
}

# AKS module
module "aks" {
  source = "./aks"

  cluster_name                = var.cluster_name
  resource_group_name         = module.vpc.resource_group_name
  location                   = var.location
  kubernetes_version         = var.kubernetes_version
  node_size_config          = var.node_size_config
  subnet_id                 = module.vpc.aks_subnet_id
  private_dns_zone_id       = module.vpc.private_dns_zone_id != null ? module.vpc.private_dns_zone_id : "System"
  network_plugin            = var.network_plugin
  network_policy            = var.network_policy
  dns_service_ip            = var.dns_service_ip
  service_cidr              = var.service_cidr
  key_vault_key_id          = var.key_vault_key_id
  enable_host_encryption    = var.enable_host_encryption
  enable_azure_policy       = var.enable_azure_policy
  enable_microsoft_defender = var.enable_microsoft_defender
  log_analytics_workspace_id = module.vpc.log_analytics_workspace_id
  enable_workload_identity  = var.enable_workload_identity
  container_registry_id     = var.container_registry_id
  workload_node_taints      = var.workload_node_taints
  environment               = var.environment
  tags                      = var.tags
}