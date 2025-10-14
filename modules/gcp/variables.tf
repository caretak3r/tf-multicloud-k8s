# Variables for GCP infrastructure module

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-east1"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the GKE cluster"
  type        = string
  default     = "1.32"
}

variable "node_size_config" {
  description = "Node size configuration (small, medium, large)"
  type        = string
  default     = "small"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "main_node_taints" {
  description = "Taints for main application node pool"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "bastion_ssh_source_ranges" {
  description = "List of source IP ranges to allow SSH access to the bastion host."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_vpc" {
  description = "Whether to create a new VPC or use an existing one."
  type        = bool
  default     = true
}

variable "enable_gke" {
  description = "Whether to create the GKE cluster."
  type        = bool
  default     = true
}

variable "enable_private_subnets" {
  description = "Enable creation of private subnets"
  type        = bool
  default     = false
}

variable "enable_public_subnets" {
  description = "Enable creation of public subnets"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable Cloud NAT for private subnets"
  type        = bool
  default     = false
}

variable "enable_private_google_access" {
  description = "Enable Private Google Access and Service Networking"
  type        = bool
  default     = false
}

variable "pods_range_name" {
  description = "The name of the pods IP range for GKE cluster"
  type        = string
  default     = "gke-pods"
}

variable "services_range_name" {
  description = "The name of the services IP range for GKE cluster"
  type        = string
  default     = "gke-services"
}

variable "master_ipv4_cidr_block" {
  description = "The master IPv4 CIDR block for GKE cluster"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for GKE cluster"
  type        = bool
  default     = false
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded Nodes for GKE cluster"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for GKE cluster"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable Network Policy for GKE cluster"
  type        = bool
  default     = true
}

variable "release_channel" {
  description = "The release channel for GKE cluster"
  type        = string
  default     = "REGULAR"
}

variable "masters_group_email" {
  description = "The email of the Google Group for GKE masters"
  type        = string
  default     = ""
}

variable "enable_filestore_csi_driver" {
  description = "Enable Filestore CSI driver for GKE cluster"
  type        = bool
  default     = true
}

variable "enable_gcs_fuse_csi_driver" {
  description = "Enable GCS Fuse CSI driver for GKE cluster"
  type        = bool
  default     = false
}

variable "logging_enabled_components" {
  description = "The logging components to enable for GKE cluster"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_enabled_components" {
  description = "The monitoring components to enable for GKE cluster"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable Vertical Pod Autoscaling for GKE cluster"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable Horizontal Pod Autoscaling for GKE cluster"
  type        = bool
  default     = true
}

variable "database_encryption_key_name" {
  description = "The KMS key resource name for GKE cluster database encryption"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "rbac_group_domain" {
  description = "The domain for RBAC group"
  type        = string
  default     = ""
}

variable "regions" {
  description = "List of regions for multi-region deployment"
  type        = list(string)
  default     = ["us-east1"]
}

variable "bastion_subnet" {
  description = "The name of the subnet to deploy the bastion host into."
  type        = string
  default     = ""
}

variable "create_bastion" {
  description = "Whether to create the bastion host."
  type        = bool
  default     = false
}

variable "bastion_authorized_keys" {
  description = "A list of public keys to authorize for SSH access to the bastion."
  type        = list(string)
  default     = []
}

variable "gke_master_to_nodes_ports" {
  description = "List of TCP ports to allow from GKE master to nodes."
  type        = list(string)
  default     = ["10250", "443", "8443", "9443", "15017", "18081", "989"]
}
