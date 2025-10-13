variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-east1"
}

variable "create_bastion" {
  description = "Whether to create the bastion host and related resources."
  type        = bool
  default     = false
}

variable "bastion_authorized_keys" {
  description = "A list of public keys to authorize for SSH access to the bastion."
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "The name of the GKE cluster to which the bastion should have access."
  type        = string
}

variable "machine_type" {
  description = "The machine type of the bastion host."
  type        = string
  default     = "e2-medium"
}

variable "zone" {
  description = "The zone where the bastion host will be created."
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork where the bastion host will be created."
  type        = string
}

variable "tags" {
  description = "A map of labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
