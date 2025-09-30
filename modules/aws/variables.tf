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

# VPC and Networking Variables
variable "vpc_id" {
  description = "VPC ID to use. If not provided, a new VPC will be created"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs. If not provided, subnets will be created or discovered"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs. If not provided, subnets will be created or discovered"
  type        = list(string)
  default     = []
}

variable "enable_eks" {
  description = "Whether to create EKS cluster"
  type        = bool
  default     = true
}

variable "enable_ecs" {
  description = "Whether to create ECS cluster and services"
  type        = bool
  default     = false
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

# ECS Configuration Variables
variable "ecs_container_image" {
  description = "Docker image for the ECS application container"
  type        = string
  default     = "nginx:latest"
}

variable "ecs_container_port" {
  description = "Port exposed by the ECS application container"
  type        = number
  default     = 8000
}

variable "ecs_secrets_sidecar_image" {
  description = "Docker image for the secrets manager sidecar"
  type        = string
  default     = "secrets-sidecar:latest"
}

variable "ecs_task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_task_cpu)
    error_message = "ECS task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
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

variable "ecs_environment_variables" {
  description = "List of environment variables for the ECS main container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "ecs_secrets" {
  description = "Map of secrets to store in AWS Secrets Manager for ECS"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "ecs_secrets_prefix" {
  description = "Prefix for ECS secrets in AWS Secrets Manager"
  type        = string
  default     = ""
}

variable "ecs_acm_certificate_arn" {
  description = "ARN of existing ACM certificate for ECS ALB (if null, self-signed certificate will be created)"
  type        = string
  default     = null
}

variable "ecs_create_self_signed_cert" {
  description = "Whether to create self-signed certificate for ECS when ACM certificate ARN is not provided"
  type        = bool
  default     = true
}

variable "ecs_domain_name" {
  description = "Domain name for ECS self-signed certificate (defaults to cluster_name.local)"
  type        = string
  default     = null
}

# ALB Configuration Variables for ECS
variable "ecs_health_check_path" {
  description = "Health check path for ECS ALB target group"
  type        = string
  default     = "/health"
}

variable "ecs_internal_alb" {
  description = "Whether the ECS ALB should be internal (private)"
  type        = bool
  default     = false
}

variable "ecs_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ECS ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecs_ssl_policy" {
  description = "SSL policy for ECS HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "ecs_enable_deletion_protection" {
  description = "Enable deletion protection for ECS ALB"
  type        = bool
  default     = false
}

variable "ecs_enable_waf" {
  description = "Enable AWS WAF for ECS ALB"
  type        = bool
  default     = true
}

variable "ecs_rate_limit_per_5min" {
  description = "Rate limit per IP per 5 minutes for ECS WAF"
  type        = number
  default     = 2000
}

variable "ecs_enable_secrets_sidecar" {
  description = "Whether to enable the secrets manager sidecar container for ECS"
  type        = bool
  default     = true
}

# ECS Launch Type Configuration
variable "ecs_launch_type" {
  description = "Launch type for ECS tasks (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["FARGATE", "EC2"], var.ecs_launch_type)
    error_message = "ECS launch type must be either FARGATE or EC2."
  }
}

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS container instances (only used when ecs_launch_type is EC2)"
  type        = string
  default     = "t3.medium"
}

variable "ecs_min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group for ECS (only used when ecs_launch_type is EC2)"
  type        = number
  default     = 1
}

variable "ecs_max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group for ECS (only used when ecs_launch_type is EC2)"
  type        = number
  default     = 3
}

variable "ecs_desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group for ECS (only used when ecs_launch_type is EC2)"
  type        = number
  default     = 2
}

variable "ecs_key_name" {
  description = "Name of the AWS key pair for ECS EC2 instances (optional, only used when ecs_launch_type is EC2)"
  type        = string
  default     = null
}

variable "ecs_enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "ecs_ec2_spot_price" {
  description = "The maximum price per hour for ECS spot instances (only used when ecs_launch_type is EC2, leave null for on-demand)"
  type        = string
  default     = null
}

variable "ecs_ebs_volume_size" {
  description = "Size of the EBS volume for ECS EC2 instances in GB (only used when ecs_launch_type is EC2)"
  type        = number
  default     = 30
}

variable "ecs_ebs_volume_type" {
  description = "Type of the EBS volume for ECS EC2 instances (only used when ecs_launch_type is EC2)"
  type        = string
  default     = "gp3"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}