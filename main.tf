terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  skip_region_validation = var.cloud_provider != "aws"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}


# AWS Infrastructure
module "aws_infrastructure" {
  source = "./modules/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  region           = var.aws_region
  cluster_name     = var.cluster_name
  environment      = var.environment
  node_size_config = var.node_size_config

  # VPC Configuration
  vpc_id               = var.vpc_id
  private_subnet_ids   = var.private_subnet_ids
  public_subnet_ids    = var.public_subnet_ids
  enable_nat_gateway   = var.enable_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints
  enable_bastion       = var.enable_bastion

  # ECS Configuration
  enable_ecs                  = var.enable_ecs
  ecs_launch_type             = var.ecs_launch_type
  ecs_container_image         = var.ecs_container_image
  ecs_container_port          = var.ecs_container_port
  ecs_instance_type           = var.ecs_instance_type
  ecs_key_name                = var.ecs_key_name
  ecs_task_cpu                = var.ecs_task_cpu
  ecs_task_memory             = var.ecs_task_memory
  ecs_desired_count           = var.ecs_desired_count
  ecs_secrets_prefix          = var.ecs_secrets_prefix
  ecs_secrets                 = var.ecs_secrets
  ecs_create_self_signed_cert = var.ecs_create_self_signed_cert
  ecs_health_check_path       = var.ecs_health_check_path
  ecs_internal_alb            = var.ecs_internal_alb
  ecs_enable_waf              = var.ecs_enable_waf

  tags = var.tags
}

# GCP Infrastructure
module "gcp_infrastructure" {
  source = "./modules/gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0

  # GCP specific variables would go here
  # This module needs to be fully implemented
}

# Azure Infrastructure
module "azure_infrastructure" {
  source = "./modules/azure"
  count  = var.cloud_provider == "azure" ? 1 : 0

  cluster_name         = var.cluster_name
  resource_group_name  = var.azure_resource_group_name
  location            = var.azure_location
  environment         = var.environment
  node_size_config    = var.node_size_config
  kubernetes_version  = var.kubernetes_version
  
  # Encryption
  key_vault_key_id    = var.azure_key_vault_key_id
  
  # Network configuration
  vnet_cidr           = var.azure_vnet_cidr
  enable_nat_gateway  = var.enable_nat_gateway
  enable_bastion      = var.enable_bastion
  
  tags = var.tags
}
