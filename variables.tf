variable "cloud_provider" {
  description = "Cloud provider to deploy to (azure, aws, or gcp)"
  type        = string
  validation {
    condition     = contains(["azure", "aws", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be either 'azure', 'aws', or 'gcp'."
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
  description = "Node size configuration based on environment"
  type        = string
  validation {
    condition     = contains(["small", "medium", "large"], var.node_size_config)
    error_message = "Node size config must be one of: small, medium, large."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ECS Configuration Variables (AWS only)
variable "enable_ecs" {
  description = "Whether to create ECS cluster and services (AWS only)"
  type        = bool
  default     = false
}

variable "ecs_launch_type" {
  description = "Launch type for ECS tasks - FARGATE or EC2 (AWS only)"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["FARGATE", "EC2"], var.ecs_launch_type)
    error_message = "ECS launch type must be either FARGATE or EC2."
  }
}

variable "ecs_container_image" {
  description = "Docker image for the ECS application container (AWS only)"
  type        = string
  default     = "nginx:latest"
}

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS container instances (only used when ecs_launch_type is EC2, AWS only)"
  type        = string
  default     = "t3.medium"
}

variable "ecs_key_name" {
  description = "Name of the AWS key pair for ECS EC2 instances (optional, only used when ecs_launch_type is EC2, AWS only)"
  type        = string
  default     = null
}

# Additional ECS Configuration Variables
variable "ecs_container_port" {
  description = "Port exposed by the ECS application container (AWS only)"
  type        = number
  default     = 8000
}

variable "ecs_task_cpu" {
  description = "CPU units for the ECS task (AWS only)"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "Memory (MB) for the ECS task (AWS only)"
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks (AWS only)"
  type        = number
  default     = 2
}

variable "ecs_secrets_prefix" {
  description = "Prefix for ECS secrets in AWS Secrets Manager (AWS only)"
  type        = string
  default     = ""
}

variable "ecs_secrets" {
  description = "Map of secrets to store in AWS Secrets Manager for ECS (AWS only)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "ecs_create_self_signed_cert" {
  description = "Whether to create self-signed certificate for ECS (AWS only)"
  type        = bool
  default     = true
}

variable "ecs_health_check_path" {
  description = "Health check path for ECS ALB target group (AWS only)"
  type        = string
  default     = "/health"
}

variable "ecs_internal_alb" {
  description = "Whether the ECS ALB should be internal/private (AWS only)"
  type        = bool
  default     = false
}

variable "ecs_enable_waf" {
  description = "Enable AWS WAF for ECS ALB (AWS only)"
  type        = bool
  default     = true
}

# Networking Variables
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

variable "vpc_id" {
  description = "VPC ID to use (AWS only). If not provided, a new VPC will be created"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (AWS only). If not provided, subnets will be created or discovered"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (AWS only). If not provided, subnets will be created or discovered"
  type        = list(string)
  default     = []
}

variable "enable_bastion" {
  description = "Whether to create bastion host"
  type        = bool
  default     = false
}

# GCP specific variables
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_database_encryption_key_name" {
  description = "Cloud KMS key name for GKE database encryption"
  type        = string
  default     = null
}

# Azure specific variables
variable "azure_resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "eastus"
}

variable "azure_key_vault_key_id" {
  description = "Azure Key Vault key ID for AKS encryption"
  type        = string
  default     = null
}

variable "azure_vnet_cidr" {
  description = "Azure VNet CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}