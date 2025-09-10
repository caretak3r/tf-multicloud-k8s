locals {
  node_size_map = {
    small = {
      vm_size                = "Standard_DS2_v2"
      node_count            = 2
      min_count            = 1
      max_count            = 5
      max_pods_per_node    = 30
    }
    medium = {
      vm_size                = "Standard_DS3_v2"
      node_count            = 3
      min_count            = 2
      max_count            = 10
      max_pods_per_node    = 50
    }
    large = {
      vm_size                = "Standard_DS4_v2"
      node_count            = 5
      min_count            = 3
      max_count            = 20
      max_pods_per_node    = 110
    }
  }
  
  node_config = local.node_size_map[var.node_size_config]
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.cluster_name}-k8s"
  
  kubernetes_version        = "1.28"
  automatic_channel_upgrade = "patch"
  sku_tier                 = "Standard"

  default_node_pool {
    name                         = "default"
    node_count                   = local.node_config.node_count
    vm_size                      = local.node_config.vm_size
    type                         = "VirtualMachineScaleSets"
    enable_auto_scaling          = true
    min_count                    = local.node_config.min_count
    max_count                    = local.node_config.max_count
    max_pods                     = local.node_config.max_pods_per_node
    os_disk_size_gb             = 128
    os_disk_type                = "Managed"
    only_critical_addons_enabled = false
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  azure_policy_enabled             = true
  http_application_routing_enabled = false
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = []
    azure_rbac_enabled     = true
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/16"
    load_balancer_sku  = "standard"
    outbound_type      = "loadBalancer"
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  api_server_access_profile {
    authorized_ip_ranges = []
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "system" {
  name                  = "system"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = "Standard_DS2_v2"
  node_count           = 2
  enable_auto_scaling = true
  min_count           = 1
  max_count           = 3
  max_pods            = 30
  os_disk_size_gb     = 128
  os_type             = "Linux"
  mode                = "System"
  
  node_taints = ["CriticalAddonsOnly=true:NoSchedule"]
  
  tags = var.tags
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_monitoring_metrics_publisher" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}