variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "create_vpc" {
  description = "Whether to create a new VPC or use existing one"
  type        = bool
  default     = true
}

variable "vpc_name" {
  description = "Name of existing VPC (required when create_vpc = false)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "regions" {
  description = "List of regions for multi-region deployment"
  type        = list(string)
  default     = ["us-central1"]
}

variable "enable_private_subnets" {
  description = "Enable creation of private subnets"
  type        = bool
  default     = true
}

variable "enable_public_subnets" {
  description = "Enable creation of public subnets"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable Cloud NAT for private subnets"
  type        = bool
  default     = true
}

variable "enable_private_google_access" {
  description = "Enable Private Google Access and Service Networking"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs (required when create_vpc = false)"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "List of existing public subnet IDs (required when create_vpc = false)"
  type        = list(string)
  default     = []
}