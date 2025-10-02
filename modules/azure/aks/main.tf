locals {
  node_size_map = {
    small = {
      vm_size            = "Standard_D2s_v3"  # 2 vCPU, 8 GB
      node_count         = 2
      min_count          = 1
      max_count          = 5
      os_disk_size_gb    = 50
    }
    medium = {
      vm_size            = "Standard_D4s_v3"  # 4 vCPU, 16 GB
      node_count         = 3
      min_count          = 2
      max_count          = 10
      os_disk_size_gb    = 100
    }
    large = {
      vm_size            = "Standard_D8s_v3"  # 8 vCPU, 32 GB
      node_count         = 5
      min_count          = 3
      max_count          = 20
      os_disk_size_gb    = 100
    }
  }

  node_config = local.node_size_map[var.node_size_config]
}

# Create Key Vault for encryption if not provided
resource "azurerm_key_vault" "aks" {
  count                       = var.key_vault_key_id == null ? 1 : 0
  name                        = "${substr(replace(var.cluster_name, "-", ""), 0, 20)}kv"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                   = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
      "List",
      "Delete",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]
  }

  tags = var.tags
}

resource "azurerm_key_vault_key" "aks" {
  count        = var.key_vault_key_id == null ? 1 : 0
  name         = "${var.cluster_name}-key"
  key_vault_id = azurerm_key_vault.aks[0].id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }

  tags = var.tags
}

# Create disk encryption set
resource "azurerm_disk_encryption_set" "aks" {
  name                = "${var.cluster_name}-des"
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_key_id    = var.key_vault_key_id != null ? var.key_vault_key_id : azurerm_key_vault_key.aks[0].id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Grant disk encryption set access to key vault
resource "azurerm_key_vault_access_policy" "disk_encryption_set" {
  key_vault_id = var.key_vault_key_id != null ? split("/keys/", var.key_vault_key_id)[0] : azurerm_key_vault.aks[0].id

  tenant_id = azurerm_disk_encryption_set.aks.identity[0].tenant_id
  object_id = azurerm_disk_encryption_set.aks.identity[0].principal_id

  key_permissions = [
    "Get",
    "UnwrapKey",
    "WrapKey"
  ]
}

data "azurerm_client_config" "current" {}

# User assigned identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# AKS Cluster - Private with encryption
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # Private cluster configuration
  private_cluster_enabled             = true
  private_dns_zone_id                 = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = false

  # Enable Azure Policy
  azure_policy_enabled = var.enable_azure_policy

  # Enable disk encryption
  disk_encryption_set_id = azurerm_disk_encryption_set.aks.id

  # Network configuration
  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    dns_service_ip     = var.dns_service_ip
    service_cidr       = var.service_cidr
    load_balancer_sku  = "standard"
    outbound_type      = "userDefinedRouting"  # For private clusters
  }

  default_node_pool {
    name                         = "system"
    node_count                   = local.node_config.node_count
    vm_size                      = local.node_config.vm_size
    os_disk_size_gb             = local.node_config.os_disk_size_gb
    vnet_subnet_id              = var.subnet_id
    type                        = "VirtualMachineScaleSets"
    enable_auto_scaling         = true
    min_count                   = local.node_config.min_count
    max_count                   = local.node_config.max_count
    enable_host_encryption      = var.enable_host_encryption
    only_critical_addons_enabled = true
    
    upgrade_settings {
      max_surge = "10%"
    }

    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = var.environment
      "nodepoolos"       = "linux"
      "app"              = "system-apps"
    }

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Enable Microsoft Defender
  microsoft_defender {
    log_analytics_workspace_id = var.enable_microsoft_defender ? var.log_analytics_workspace_id : null
  }

  # Enable OIDC and workload identity
  oidc_issuer_enabled       = var.enable_workload_identity
  workload_identity_enabled = var.enable_workload_identity

  # Key Management Service for etcd encryption
  key_management_service {
    key_vault_key_id         = var.key_vault_key_id != null ? var.key_vault_key_id : azurerm_key_vault_key.aks[0].id
    key_vault_network_access = "Private"
  }

  # Auto-scaler profile
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                          = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "0s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
  }

  # Maintenance window
  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = [1, 4]
    }
    allowed {
      day   = "Sunday"  
      hours = [1, 4]
    }
  }

  tags = var.tags
}

# Additional node pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = local.node_config.vm_size
  node_count           = local.node_config.node_count
  vnet_subnet_id       = var.subnet_id
  
  enable_auto_scaling    = true
  min_count             = local.node_config.min_count
  max_count             = local.node_config.max_count
  enable_host_encryption = var.enable_host_encryption
  os_disk_size_gb       = local.node_config.os_disk_size_gb

  node_labels = {
    "nodepool-type" = "workload"
    "environment"   = var.environment
  }

  node_taints = var.workload_node_taints

  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags
}

# Grant AKS identity access to ACR if provided
resource "azurerm_role_assignment" "aks_acr" {
  count                = var.container_registry_id != null ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name = "AcrPull"
  scope                = var.container_registry_id
}

# Network contributor role for AKS identity on subnet
resource "azurerm_role_assignment" "aks_network" {
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name = "Network Contributor"
  scope                = var.subnet_id
}