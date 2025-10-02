# Azure AKS Cluster Example Configuration
# Kubernetes version 1.32

# General Configuration
location            = "eastus"
resource_group_name = "my-company-rg"
environment         = "production"

# VPC (VNet) Configuration
create_vpc             = true  # Set to false to use existing VNet
vpc_name               = ""    # Required if create_vpc = false
vpc_cidr              = "10.0.0.0/16"
address_prefixes      = ["10.0.0.0/20"]
enable_private_subnets = true
enable_public_subnets  = true
enable_nat_gateway    = true

# Existing VNet Configuration (when create_vpc = false)
# vpc_id    = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx"
# subnet_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx/subnets/xxx"

# AKS Cluster Configuration
cluster_name       = "aks-cluster"
kubernetes_version = "1.32"
node_size_config  = "medium"  # Options: small, medium, large

# Network Configuration
network_plugin      = "azure"
network_policy      = "azure"
dns_service_ip      = "10.0.0.10"
service_cidr        = "10.0.0.0/16"
private_dns_zone_id = "System"  # Use "System" for Azure-managed DNS

# Security & Compliance
enable_host_encryption    = true
enable_azure_policy       = true
enable_microsoft_defender = true
enable_workload_identity  = true

# Container Registry (optional)
container_registry_id = null  # Set to ACR resource ID if needed

# Monitoring (optional)
log_analytics_workspace_id = null  # Set to existing workspace ID or leave null

# Node Pool Configuration
workload_node_taints = []

# Tags
tags = {
  Environment = "production"
  ManagedBy   = "terraform"
  Cluster     = "aks-cluster"
}