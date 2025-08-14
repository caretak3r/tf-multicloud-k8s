variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS cluster"
  type        = list(string)
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

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "bastion_security_group_id" {
  description = "Security group ID of bastion host (optional)"
  type        = string
  default     = null
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}