variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Module Control Variables
variable "create_vpc" {
  description = "Whether to create a new VPC"
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "ID of existing VPC (required if create_vpc is false)"
  type        = string
  default     = null
}

variable "enable_eks" {
  description = "Whether to create EKS cluster"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Whether to create bastion host"
  type        = bool
  default     = false
}

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

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
  validation {
    condition     = var.availability_zones_count >= 2 && var.availability_zones_count <= 6
    error_message = "Availability zones count must be between 2 and 6."
  }
}

# EKS Configuration
variable "node_size_config" {
  description = "Node size configuration (small, medium, large)"
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.node_size_config)
    error_message = "Node size config must be one of: small, medium, large."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "ami_type" {
  description = "AMI type for EKS worker nodes"
  type        = string
  default     = "AL2_x86_64"
}

variable "capacity_type" {
  description = "Capacity type for EKS worker nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "enabled_cluster_log_types" {
  description = "List of cluster log types to enable"
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "node_ssh_key_name" {
  description = "EC2 Key Pair name for SSH access to worker nodes"
  type        = string
  default     = null
}

variable "addon_versions" {
  description = "Versions for EKS add-ons"
  type = object({
    vpc_cni    = optional(string, null)
    coredns    = optional(string, null)
    kube_proxy = optional(string, null)
    ebs_csi    = optional(string, null)
  })
  default = {}
}

# Bastion Configuration
variable "bastion_key_name" {
  description = "EC2 Key Pair name for SSH access to bastion host"
  type        = string
  default     = null
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = []
  validation {
    condition = length(var.bastion_allowed_ssh_cidr_blocks) == 0 || alltrue([
      for cidr in var.bastion_allowed_ssh_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All provided CIDR blocks must be valid."
  }
}

# Common Configuration
variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}