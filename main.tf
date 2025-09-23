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
  node_size_config   = var.node_size_config
  tags               = var.tags
}

module "aws_infrastructure" {
  source = "./modules/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  region           = var.aws_region
  cluster_name     = var.cluster_name
  environment      = var.environment
  node_size_config = var.node_size_config
  
  # VPC Configuration
  create_vpc             = var.create_vpc
  existing_vpc_id        = var.existing_vpc_id
  enable_nat_gateway     = var.enable_nat_gateway
  enable_vpc_endpoints   = var.enable_vpc_endpoints
  enable_bastion         = var.enable_bastion
  
  # ECS Configuration
  enable_ecs                    = var.enable_ecs
  ecs_launch_type               = var.ecs_launch_type
  ecs_container_image           = var.ecs_container_image
  ecs_container_port            = var.ecs_container_port
  ecs_instance_type             = var.ecs_instance_type
  ecs_key_name                  = var.ecs_key_name
  ecs_task_cpu                  = var.ecs_task_cpu
  ecs_task_memory               = var.ecs_task_memory
  ecs_desired_count             = var.ecs_desired_count
  ecs_secrets_prefix            = var.ecs_secrets_prefix
  ecs_secrets                   = var.ecs_secrets
  ecs_create_self_signed_cert   = var.ecs_create_self_signed_cert
  ecs_health_check_path         = var.ecs_health_check_path
  ecs_internal_alb              = var.ecs_internal_alb
  ecs_enable_waf                = var.ecs_enable_waf
  
  tags = var.tags
}