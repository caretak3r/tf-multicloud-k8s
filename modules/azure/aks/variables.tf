variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "node_size_config" {
  description = "Node size configuration (small, medium, large)"
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.node_size_config)
    error_message = "Node size config must be one of: small, medium, large."
  }
}

variable "subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for private cluster"
  type        = string
  default     = "System"
}

variable "network_plugin" {
  description = "Network plugin for AKS (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy for AKS"
  type        = string
  default     = "azure"
}

variable "dns_service_ip" {
  description = "DNS service IP address"
  type        = string
  default     = "10.0.0.10"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "key_vault_key_id" {
  description = "ID of existing Key Vault key for encryption. If not provided, a new key will be created."
  type        = string
  default     = null
}

variable "enable_host_encryption" {
  description = "Enable host encryption for nodes"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = true
}

variable "enable_microsoft_defender" {
  description = "Enable Microsoft Defender for Cloud"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = null
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "container_registry_id" {
  description = "Azure Container Registry ID to grant pull access"
  type        = string
  default     = null
}

variable "workload_node_taints" {
  description = "Taints for workload node pool"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}