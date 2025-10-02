variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "create_vpc" {
  description = "Whether to create a new VNet or use existing one"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of existing VNet (required when create_vpc = false)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID of existing subnet for AKS (required when create_vpc = false)"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for bastion subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound internet access"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure remote access"
  type        = bool
  default     = false
}

variable "create_private_dns_zone" {
  description = "Create private DNS zone for AKS"
  type        = bool
  default     = true
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics workspace"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}