variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where bastion host will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for bastion host"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster for kubectl configuration"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for bastion host (defaults to latest Amazon Linux 2)"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 8
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  validation {
    condition = length(var.allowed_ssh_cidr_blocks) > 0 && alltrue([
      for cidr in var.allowed_ssh_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "At least one valid CIDR block must be provided for SSH access."
  }
}

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