variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network_name" {
  description = "Name of the existing VPC network"
  type        = string
}

variable "subnetwork_name" {
  description = "Name of the existing subnet for GKE cluster"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
  default     = "gke-pods"
}

variable "services_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
  default     = "gke-services"
}

variable "node_size_config" {
  description = "Node size configuration (small, medium, large)"
  type        = string
  default     = "large"
  validation {
    condition     = contains(["small", "medium", "large"], var.node_size_config)
    error_message = "Node size config must be one of: small, medium, large."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for GKE cluster"
  type        = string
  default     = "1.32"
}

variable "release_channel" {
  description = "GKE release channel"
  type        = string
  default     = "REGULAR"
}

variable "master_authorized_networks" {
  description = "List of networks allowed to access the Kubernetes master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation for the master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "rbac_group_domain" {
  description = "Google Groups domain for RBAC"
  type        = string
  default     = ""
}

variable "masters_group_email" {
  description = "Email of the Google Group for cluster masters/admins"
  type        = string
  default     = ""
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = false
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE nodes"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "enable_filestore_csi_driver" {
  description = "Enable Filestore CSI driver"
  type        = bool
  default     = true
}

variable "enable_gcs_fuse_csi_driver" {
  description = "Enable GCS FUSE CSI driver"
  type        = bool
  default     = false
}

variable "logging_enabled_components" {
  description = "List of GKE components to log"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_enabled_components" {
  description = "List of GKE components to monitor"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable vertical pod autoscaling"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "database_encryption_key_name" {
  description = "The Cloud KMS key name to use for cluster database encryption. Format: projects/PROJECT_ID/locations/LOCATION/keyRings/RING_NAME/cryptoKeys/KEY_NAME. If not provided, a new key will be created."
  type        = string
  default     = null
}

variable "labels" {
  description = "A map of labels to apply to all resources"
  type        = map(string)
  default     = {}
}