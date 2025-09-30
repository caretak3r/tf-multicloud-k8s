variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "At least one private subnet ID must be provided for ECS tasks."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "container_image" {
  description = "Docker image for the main application container"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the main application container"
  type        = number
  default     = 8000
}

variable "secrets_sidecar_image" {
  description = "Docker image for the secrets manager sidecar"
  type        = string
  default     = "secrets-sidecar:latest"
}

variable "task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory (MB) for the ECS task"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "environment_variables" {
  description = "List of environment variables for the main container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Map of secrets to store in AWS Secrets Manager"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "secrets_prefix" {
  description = "Prefix for secrets in AWS Secrets Manager"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of existing ACM certificate (if null, self-signed certificate will be created)"
  type        = string
  default     = null
}

variable "create_self_signed_cert" {
  description = "Whether to create self-signed certificate when ACM certificate ARN is not provided"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for self-signed certificate (defaults to cluster_name.local)"
  type        = string
  default     = null
}

# Note: ALB integration handled at main module level to avoid circular dependencies

variable "enable_secrets_sidecar" {
  description = "Whether to enable the secrets manager sidecar container"
  type        = bool
  default     = true
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

# EC2 Launch Type Variables
variable "launch_type" {
  description = "Launch type for ECS tasks (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "Launch type must be either FARGATE or EC2."
  }
}

variable "node_size_config" {
  description = "Node size configuration for ECS EC2 instances: small, medium, or large"
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.node_size_config)
    error_message = "Node size config must be 'small', 'medium', or 'large'."
  }
}

variable "instance_type" {
  description = "EC2 instance type for ECS container instances (only used when launch_type is EC2, overrides node_size_config)"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group (only used when launch_type is EC2, overrides node_size_config)"
  type        = number
  default     = null
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group (only used when launch_type is EC2, overrides node_size_config)"
  type        = number
  default     = null
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group (only used when launch_type is EC2, overrides node_size_config)"
  type        = number
  default     = null
}

variable "key_name" {
  description = "Name of the AWS key pair for EC2 instances (optional, only used when launch_type is EC2)"
  type        = string
  default     = null
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "ec2_spot_price" {
  description = "The maximum price per hour for spot instances (only used when launch_type is EC2, leave null for on-demand)"
  type        = string
  default     = null
}

variable "ebs_volume_size" {
  description = "Size of the EBS volume for EC2 instances in GB (only used when launch_type is EC2, overrides node_size_config)"
  type        = number
  default     = null
}

variable "ebs_volume_type" {
  description = "Type of the EBS volume for EC2 instances (only used when launch_type is EC2)"
  type        = string
  default     = "gp3"
}