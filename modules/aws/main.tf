# VPC Module
module "vpc" {
  source = "./vpc"
  count  = var.create_vpc ? 1 : 0

  name_prefix               = var.cluster_name
  vpc_cidr                  = var.vpc_cidr
  availability_zones_count  = var.availability_zones_count
  enable_private_subnets    = true
  enable_public_subnets     = var.enable_bastion || var.enable_nat_gateway
  enable_nat_gateway        = var.enable_nat_gateway
  enable_vpc_endpoints      = var.enable_vpc_endpoints

  tags = var.tags
}

# Use existing VPC data if not creating new one
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.existing_vpc_id
}

data "aws_subnets" "existing_private" {
  count = var.create_vpc || length(var.existing_private_subnet_ids) > 0 ? 0 : 1
  
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

data "aws_subnets" "existing_public" {
  count = var.create_vpc || length(var.existing_public_subnet_ids) > 0 ? 0 : 1
  
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

# Local values for VPC resources
locals {
  vpc_id              = var.create_vpc ? module.vpc[0].vpc_id : data.aws_vpc.existing[0].id
  vpc_cidr_block      = var.create_vpc ? module.vpc[0].vpc_cidr_block : data.aws_vpc.existing[0].cidr_block
  private_subnet_ids  = var.create_vpc ? module.vpc[0].private_subnet_ids : (length(var.existing_private_subnet_ids) > 0 ? var.existing_private_subnet_ids : (length(data.aws_subnets.existing_private) > 0 ? data.aws_subnets.existing_private[0].ids : []))
  public_subnet_ids   = var.create_vpc ? module.vpc[0].public_subnet_ids : (length(var.existing_public_subnet_ids) > 0 ? var.existing_public_subnet_ids : (length(data.aws_subnets.existing_public) > 0 ? data.aws_subnets.existing_public[0].ids : []))
}

# Bastion Host Module (optional)
module "bastion" {
  source = "./bastion"
  count  = var.enable_bastion ? 1 : 0

  name_prefix             = var.cluster_name
  vpc_id                  = local.vpc_id
  vpc_cidr_block          = local.vpc_cidr_block
  public_subnet_id        = local.public_subnet_ids[0]
  cluster_name            = var.cluster_name
  region                  = var.region
  key_name                = var.bastion_key_name
  instance_type           = var.bastion_instance_type
  allowed_ssh_cidr_blocks = var.bastion_allowed_ssh_cidr_blocks
  log_retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

# EKS Cluster Module
module "eks" {
  source = "./eks"
  count  = var.enable_eks ? 1 : 0

  cluster_name               = var.cluster_name
  vpc_id                     = local.vpc_id
  vpc_cidr_block             = local.vpc_cidr_block
  private_subnet_ids         = local.private_subnet_ids
  node_size_config           = var.node_size_config
  kubernetes_version         = var.kubernetes_version
  ami_type                   = var.ami_type
  capacity_type              = var.capacity_type
  enabled_cluster_log_types  = var.enabled_cluster_log_types
  log_retention_in_days      = var.log_retention_in_days
  bastion_security_group_id  = var.enable_bastion ? module.bastion[0].bastion_security_group_id : null
  node_ssh_key_name          = var.node_ssh_key_name
  addon_versions             = var.addon_versions

  tags = var.tags

  depends_on = [module.vpc, module.bastion]
}

# ECS Module (creates cluster, certificates, and tasks)
module "ecs" {
  source = "./ecs"
  count  = var.enable_ecs ? 1 : 0

  cluster_name              = var.cluster_name
  vpc_id                    = local.vpc_id
  private_subnet_ids        = local.private_subnet_ids
  region                    = var.region
  container_image           = var.ecs_container_image
  container_port            = var.ecs_container_port
  secrets_sidecar_image     = var.ecs_secrets_sidecar_image
  task_cpu                  = var.ecs_task_cpu
  task_memory               = var.ecs_task_memory
  desired_count             = var.ecs_desired_count
  environment_variables     = var.ecs_environment_variables
  secrets                   = var.ecs_secrets
  secrets_prefix            = var.ecs_secrets_prefix
  acm_certificate_arn       = var.ecs_acm_certificate_arn
  create_self_signed_cert   = var.ecs_create_self_signed_cert
  domain_name               = var.ecs_domain_name
  enable_secrets_sidecar    = var.ecs_enable_secrets_sidecar
  log_retention_in_days     = var.log_retention_in_days

  tags = var.tags

  depends_on = [module.vpc]
}

# Application Load Balancer Module (for ECS)
module "alb" {
  source = "./alb"
  count  = var.enable_ecs ? 1 : 0

  cluster_name              = var.cluster_name
  vpc_id                    = local.vpc_id
  public_subnet_ids         = local.public_subnet_ids
  private_subnet_ids        = local.private_subnet_ids
  certificate_arn           = var.ecs_acm_certificate_arn != null ? var.ecs_acm_certificate_arn : module.ecs[0].certificate_arn
  target_port               = var.ecs_container_port
  health_check_path         = var.ecs_health_check_path
  internal_alb              = var.ecs_internal_alb
  allowed_cidr_blocks       = var.ecs_allowed_cidr_blocks
  ssl_policy                = var.ecs_ssl_policy
  enable_deletion_protection = var.ecs_enable_deletion_protection
  enable_waf                = var.ecs_enable_waf
  rate_limit_per_5min       = var.ecs_rate_limit_per_5min

  tags = var.tags

  depends_on = [module.vpc, module.ecs]
}

# Security Group Rule: Allow ALB to access ECS tasks
resource "aws_security_group_rule" "alb_to_ecs" {
  count                    = var.enable_ecs ? 1 : 0
  type                     = "ingress"
  from_port                = var.ecs_container_port
  to_port                  = var.ecs_container_port
  protocol                 = "tcp"
  source_security_group_id = module.alb[0].security_group_id
  security_group_id        = module.ecs[0].security_group_id

  depends_on = [module.ecs, module.alb]
}

# Update ECS service with ALB target group (separate resource to avoid circular dependency)
resource "aws_ecs_service" "main_with_alb" {
  count           = var.enable_ecs ? 1 : 0
  name            = "${var.cluster_name}-with-alb"
  cluster         = module.ecs[0].cluster_id
  task_definition = module.ecs[0].task_definition_arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [module.ecs[0].security_group_id]
    subnets          = local.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb[0].target_group_arn
    container_name   = "app"
    container_port   = var.ecs_container_port
  }

  depends_on = [module.ecs, module.alb, aws_security_group_rule.alb_to_ecs]

  tags = var.tags

  lifecycle {
    ignore_changes = [task_definition]
  }
}