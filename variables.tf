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
  description = "Node size configuration based on environment (only used for EKS)"
  type        = string
  default     = "medium"
  validation {
    condition     = contains(["small", "medium", "large"], var.node_size_config)
    error_message = "Node size config must be one of: small, medium, large."
  }
}

# Module Control Variables
variable "enable_eks" {
  description = "Enable EKS module"
  type        = bool
  default     = false
}

variable "enable_ecs" {
  description = "Enable ECS module"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Enable bastion host"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints"
  type        = bool
  default     = false
}

# VPC Configuration
variable "create_vpc" {
  description = "Whether to create a new VPC or use existing"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "Existing VPC ID (when create_vpc is false)"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Existing private subnet IDs (when create_vpc is false)"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "Existing public subnet IDs (when create_vpc is false)"
  type        = list(string)
  default     = []
}

# ECS Variables
variable "ecs_container_image" {
  description = "Docker image for the main ECS container"
  type        = string
  default     = ""
}

variable "ecs_container_port" {
  description = "Port exposed by the main ECS container"
  type        = number
  default     = 8000
}

variable "ecs_task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "Memory (MB) for the ECS task"
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_enable_secrets_sidecar" {
  description = "Whether to enable the secrets manager sidecar container"
  type        = bool
  default     = true
}

variable "ecs_secrets_sidecar_image" {
  description = "Docker image for the secrets manager sidecar"
  type        = string
  default     = "secrets-sidecar:latest"
}

variable "ecs_environment_variables" {
  description = "List of environment variables for the main ECS container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "ecs_secrets" {
  description = "Map of secrets to store in AWS Secrets Manager"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "ecs_secrets_prefix" {
  description = "Prefix for secrets in AWS Secrets Manager"
  type        = string
  default     = ""
}

variable "ecs_health_check_path" {
  description = "Health check path for ECS service"
  type        = string
  default     = "/health"
}

variable "ecs_internal_alb" {
  description = "Whether the ALB should be internal"
  type        = bool
  default     = false
}

variable "ecs_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecs_ssl_policy" {
  description = "SSL policy for ECS HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "ecs_acm_certificate_arn" {
  description = "ARN of existing ACM certificate for ALB"
  type        = string
  default     = null
}

variable "ecs_create_self_signed_cert" {
  description = "Whether to create self-signed certificate for ECS containers"
  type        = bool
  default     = true
}

variable "ecs_domain_name" {
  description = "Domain name for self-signed certificate"
  type        = string
  default     = null
}


variable "ecs_enable_deletion_protection" {
  description = "Whether to enable deletion protection for ALB"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}