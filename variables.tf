variable "cloud_provider" {
  description = "Cloud provider to deploy to (azure, aws, or gcp)"
  type        = string
  validation {
    condition     = contains(["azure", "aws", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be either 'azure', 'aws', or 'gcp'."
  }
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, perf)"
  type        = string
}

variable "resource_group_name" {
  description = "Azure resource group name (only used for Azure)"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure location (only used for Azure)"
  type        = string
  default     = "East US"
}

variable "aws_region" {
  description = "AWS region (only used for AWS)"
  type        = string
  default     = "us-east-1"
}

variable "node_size_config" {
  description = "Node size configuration based on environment"
  type        = string
  validation {
    condition     = contains(["small", "medium", "large"], var.node_size_config)
    error_message = "Node size config must be one of: small, medium, large."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}


# Networking Variables
variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Whether to create VPC endpoints for AWS services"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID to use (AWS only). If not provided, a new VPC will be created"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (AWS only). If not provided, subnets will be created or discovered"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (AWS only). If not provided, subnets will be created or discovered"
  type        = list(string)
  default     = []
}

variable "enable_bastion" {
  description = "Whether to create bastion host"
  type        = bool
  default     = false
}

# GCP specific variables
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_database_encryption_key_name" {
  description = "Cloud KMS key name for GKE database encryption"
  type        = string
  default     = null
}

# Azure specific variables
variable "azure_resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "eastus"
}

variable "azure_key_vault_key_id" {
  description = "Azure Key Vault key ID for AKS encryption"
  type        = string
  default     = null
}

variable "azure_vnet_cidr" {
  description = "Azure VNet CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}