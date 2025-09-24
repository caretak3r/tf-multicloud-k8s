variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "create_vpc" {
  description = "Whether to create a new VPC or use existing subnets"
  type        = bool
  default     = true
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

variable "vpc_id" {
  description = "Existing VPC ID (required when create_vpc = false)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use (only applies when create_vpc = true)"
  type        = number
  default     = 3
  validation {
    condition     = var.availability_zones_count >= 2 && var.availability_zones_count <= 6
    error_message = "Availability zones count must be between 2 and 6."
  }
}

variable "enable_private_subnets" {
  description = "Whether to create private subnets (only applies when create_vpc = true)"
  type        = bool
  default     = true
}

variable "enable_public_subnets" {
  description = "Whether to create public subnets (only applies when create_vpc = true)"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways for private subnets (only applies when create_vpc = true)"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Whether to create VPC endpoints for AWS services (only applies when create_vpc = true)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}