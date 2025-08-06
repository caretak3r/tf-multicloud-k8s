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

module "aws_eks" {
  source = "./modules/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  region           = var.aws_region
  cluster_name     = var.cluster_name
  environment      = var.environment
  node_size_config = var.node_size_config
  tags             = var.tags
}