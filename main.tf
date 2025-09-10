terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "aws" {
  region = var.aws_region
}

module "azure_aks" {
  source = "./modules/azure"
  count  = var.cloud_provider == "azure" ? 1 : 0

  resource_group_name = var.resource_group_name
  location           = var.location
  cluster_name       = var.cluster_name
  environment        = var.environment
  node_size_config   = var.node_size_config  # Azure only supports AKS, so always required
  tags               = var.tags
}

module "aws_infrastructure" {
  source = "./modules/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  region           = var.aws_region
  cluster_name     = var.cluster_name
  environment      = var.environment
  node_size_config = var.enable_eks ? var.node_size_config : "medium"
  tags             = var.tags
  
  # Module Control
  create_vpc                   = var.create_vpc
  existing_vpc_id              = var.vpc_id
  existing_private_subnet_ids  = var.private_subnet_ids
  existing_public_subnet_ids   = var.public_subnet_ids
  enable_eks                   = var.enable_eks
  enable_ecs               = var.enable_ecs
  enable_bastion           = var.enable_bastion
  enable_nat_gateway       = var.enable_nat_gateway
  enable_vpc_endpoints     = var.enable_vpc_endpoints
  log_retention_in_days    = var.log_retention_in_days
  
  # ECS Configuration
  ecs_container_image               = var.ecs_container_image
  ecs_container_port               = var.ecs_container_port
  ecs_secrets_sidecar_image        = var.ecs_secrets_sidecar_image
  ecs_task_cpu                     = var.ecs_task_cpu
  ecs_task_memory                  = var.ecs_task_memory
  ecs_desired_count                = var.ecs_desired_count
  ecs_environment_variables        = var.ecs_environment_variables
  ecs_secrets                      = var.ecs_secrets
  ecs_secrets_prefix               = var.ecs_secrets_prefix
  ecs_acm_certificate_arn          = var.ecs_acm_certificate_arn
  ecs_create_self_signed_cert      = var.ecs_create_self_signed_cert
  ecs_domain_name                  = var.ecs_domain_name
  ecs_health_check_path            = var.ecs_health_check_path
  ecs_internal_alb                 = var.ecs_internal_alb
  ecs_allowed_cidr_blocks          = var.ecs_allowed_cidr_blocks
  ecs_ssl_policy                   = var.ecs_ssl_policy
  ecs_enable_deletion_protection   = var.ecs_enable_deletion_protection
  ecs_enable_waf                   = var.ecs_enable_waf
  ecs_rate_limit_per_5min          = var.ecs_rate_limit_per_5min
  ecs_enable_secrets_sidecar       = var.ecs_enable_secrets_sidecar
}