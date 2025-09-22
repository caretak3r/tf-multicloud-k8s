variable "cloud_provider" {
  description = "Cloud provider to deploy to (azure or aws)"
  type        = string
  validation {
    condition     = contains(["azure", "aws"], var.cloud_provider)
    error_message = "Cloud provider must be either 'azure' or 'aws'."
  }
}

variable "cluster_name" {
  description = "Name of the cluster (Kubernetes EKS or ECS)"
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