pipeline {
    agent any
    
    environment {
        AWS_ZIP_NAME = 'aws.zip'
        AZURE_ZIP_NAME = 'azure.zip'
        AWS_BUILD_DIR = 'aws-build'
        AZURE_BUILD_DIR = 'azure-build'
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    // Clean up any existing build directories
                    sh 'rm -rf ${AWS_BUILD_DIR} ${AZURE_BUILD_DIR} *.zip'
                    
                    // Create build directories
                    sh 'mkdir -p ${AWS_BUILD_DIR} ${AZURE_BUILD_DIR}'
                }
            }
        }
        
        stage('Prepare AWS Package') {
            steps {
                script {
                    // Copy all files except .git, .terraform, and build directories
                    sh '''
                        cp -r . ${AWS_BUILD_DIR}/
                        cd ${AWS_BUILD_DIR}
                        rm -rf .git .terraform ${AWS_BUILD_DIR} ${AZURE_BUILD_DIR} *.zip
                    '''
                    
                    // Create AWS-specific main.tf (remove Azure provider and module)
                    sh '''
                        cd ${AWS_BUILD_DIR}
                        cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "aws_infrastructure" {
  source = "./modules/aws"
  count  = 1

  region           = var.aws_region
  cluster_name     = var.cluster_name
  environment      = var.environment
  node_size_config = var.enable_eks ? var.node_size_config : "medium"
  tags             = var.tags

  # Module Control
  create_vpc                  = var.create_vpc
  existing_vpc_id             = var.vpc_id
  existing_private_subnet_ids = var.private_subnet_ids
  existing_public_subnet_ids  = var.public_subnet_ids
  enable_eks                  = var.enable_eks
  enable_ecs                  = var.enable_ecs
  enable_bastion              = var.enable_bastion
  enable_nat_gateway          = var.enable_nat_gateway
  enable_vpc_endpoints        = var.enable_vpc_endpoints
  log_retention_in_days       = var.log_retention_in_days

  # ECS Configuration
  ecs_container_image            = var.ecs_container_image
  ecs_container_port             = var.ecs_container_port
  ecs_secrets_sidecar_image      = var.ecs_secrets_sidecar_image
  ecs_task_cpu                   = var.ecs_task_cpu
  ecs_task_memory                = var.ecs_task_memory
  ecs_desired_count              = var.ecs_desired_count
  ecs_environment_variables      = var.ecs_environment_variables
  ecs_secrets                    = var.ecs_secrets
  ecs_secrets_prefix             = var.ecs_secrets_prefix
  ecs_acm_certificate_arn        = var.ecs_acm_certificate_arn
  ecs_create_self_signed_cert    = var.ecs_create_self_signed_cert
  ecs_domain_name                = var.ecs_domain_name
  ecs_health_check_path          = var.ecs_health_check_path
  ecs_internal_alb               = var.ecs_internal_alb
  ecs_allowed_cidr_blocks        = var.ecs_allowed_cidr_blocks
  ecs_ssl_policy                 = var.ecs_ssl_policy
  ecs_enable_deletion_protection = var.ecs_enable_deletion_protection
  ecs_enable_secrets_sidecar     = var.ecs_enable_secrets_sidecar
}
EOF
                    '''
                    
                    // Remove Azure modules and Azure-specific files
                    sh '''
                        cd ${AWS_BUILD_DIR}
                        rm -rf modules/azure
                    '''
                    
                    // Create AWS-specific terraform.tfvars.example
                    sh '''
                        cd ${AWS_BUILD_DIR}
                        cat > terraform.tfvars.example << 'EOF'
# AWS Terraform configuration
# Copy this file to terraform.tfvars and customize for your environment

# Cluster configuration
cluster_name = "my-k8s-cluster"
environment  = "dev"

# Node size configuration: "small", "medium", or "large"
node_size_config = "small"

# AWS-specific variables
aws_region = "us-east-1"

# VPC Configuration
create_vpc = true
# If using existing VPC, set create_vpc = false and specify:
# vpc_id = "vpc-xxxxxxxxx"
# private_subnet_ids = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
# public_subnet_ids = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]

# Module Control
enable_eks = true
enable_ecs = false
enable_bastion = false
enable_nat_gateway = true
enable_vpc_endpoints = false
log_retention_in_days = 7

# ECS Configuration (if enable_ecs = true)
# ecs_container_image = "nginx:latest"
# ecs_container_port = 80
# ecs_task_cpu = 256
# ecs_task_memory = 512
# ecs_desired_count = 2

# Common tags
tags = {
  Environment = "dev"
  Project     = "kubernetes-cluster"
  Team        = "devops"
  Owner       = "your-team@company.com"
}
EOF
                    '''
                }
            }
        }
        
        stage('Prepare Azure Package') {
            steps {
                script {
                    // Copy all files except .git, .terraform, and build directories
                    sh '''
                        cp -r . ${AZURE_BUILD_DIR}/
                        cd ${AZURE_BUILD_DIR}
                        rm -rf .git .terraform ${AWS_BUILD_DIR} ${AZURE_BUILD_DIR} *.zip
                    '''
                    
                    // Create Azure-specific main.tf (remove AWS provider and module)
                    sh '''
                        cd ${AZURE_BUILD_DIR}
                        cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

module "azure_aks" {
  source = "./modules/azure"
  count  = 1

  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = var.cluster_name
  environment         = var.environment
  node_size_config    = var.node_size_config
  tags                = var.tags
}
EOF
                    '''
                    
                    // Remove AWS modules and AWS-specific files
                    sh '''
                        cd ${AZURE_BUILD_DIR}
                        rm -rf modules/aws
                    '''
                    
                    // Create Azure-specific terraform.tfvars.example
                    sh '''
                        cd ${AZURE_BUILD_DIR}
                        cat > terraform.tfvars.example << 'EOF'
# Azure Terraform configuration  
# Copy this file to terraform.tfvars and customize for your environment

# Cluster configuration
cluster_name = "my-k8s-cluster"
environment  = "dev"

# Node size configuration: "small", "medium", or "large"
node_size_config = "small"

# Azure-specific variables
resource_group_name = "my-k8s-rg"
location           = "East US"

# Common tags
tags = {
  Environment = "dev"
  Project     = "kubernetes-cluster"
  Team        = "devops"
  Owner       = "your-team@company.com"
}
EOF
                    '''
                }
            }
        }
        
        stage('Create Zip Files') {
            parallel {
                stage('Create AWS Zip') {
                    steps {
                        script {
                            sh 'cd ${AWS_BUILD_DIR} && zip -r ../${AWS_ZIP_NAME} .'
                        }
                    }
                }
                stage('Create Azure Zip') {
                    steps {
                        script {
                            sh 'cd ${AZURE_BUILD_DIR} && zip -r ../${AZURE_ZIP_NAME} .'
                        }
                    }
                }
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                script {
                    // Archive the zip files
                    archiveArtifacts artifacts: '*.zip', fingerprint: true
                    
                    // Display file sizes for verification
                    sh 'ls -lh *.zip'
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean up build directories
                sh 'rm -rf ${AWS_BUILD_DIR} ${AZURE_BUILD_DIR}'
            }
        }
        success {
            echo 'Successfully created AWS and Azure deployment packages!'
        }
        failure {
            echo 'Failed to create deployment packages. Check the logs for details.'
        }
    }
}