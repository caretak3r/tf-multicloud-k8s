locals {
  node_size_map = {
    small = {
      instance_types = ["c5.large"]
      desired_size   = 2
      min_size       = 1
      max_size       = 5
      disk_size      = 20
    }
    medium = {
      instance_types = ["c5.xlarge"]
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      disk_size      = 30
    }
    large = {
      instance_types = ["c5.2xlarge"]
      desired_size   = 5
      min_size       = 3
      max_size       = 20
      disk_size      = 50
    }
  }

  node_config = local.node_size_map[var.node_size_config]
}

data "aws_caller_identity" "current" {}

# Security group for EKS cluster control plane
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # Bastion access (if enabled)
  dynamic "ingress" {
    for_each = var.bastion_security_group_id != null ? [1] : []
    content {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [var.bastion_security_group_id]
      description     = "Allow HTTPS from bastion host"
    }
  }

  # Restrict egress to VPC CIDR only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow all traffic within VPC"
  }

  # Allow HTTPS to VPC endpoints
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow HTTPS to VPC endpoints"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })
}

# Security group for EKS worker nodes
resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow all traffic between nodes
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow all TCP traffic between worker nodes"
  }

  # Allow traffic from VPC CIDR (including control plane)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow all TCP traffic from VPC (including control plane)"
  }

  # Allow SSH from bastion if enabled
  dynamic "ingress" {
    for_each = var.bastion_security_group_id != null ? [1] : []
    content {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [var.bastion_security_group_id]
      description     = "Allow SSH from bastion host"
    }
  }

  # Restrict egress to VPC CIDR only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow all traffic within VPC"
  }

  # Allow HTTPS to VPC endpoints for ECR, etc.
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow HTTPS to VPC endpoints"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nodes-sg"
  })
}

# IAM role for EKS cluster
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# IAM role for EKS worker nodes
resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# User must provide KMS key - no automatic key creation

# CloudWatch log group for EKS cluster
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

# EKS Cluster - Private endpoint only
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = false # Private only!
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy,
    aws_cloudwatch_log_group.cluster,
  ]
}

# EKS Node Group - Main Application
resource "aws_eks_node_group" "main_app" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-main-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = local.node_config.instance_types
  disk_size       = local.node_config.disk_size
  ami_type        = var.ami_type
  capacity_type   = var.capacity_type

  scaling_config {
    desired_size = local.node_config.desired_size
    max_size     = local.node_config.max_size
    min_size     = local.node_config.min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Apply taints for main application node group
  dynamic "taint" {
    for_each = var.main_node_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Only allow SSH if bastion is provided
  dynamic "remote_access" {
    for_each = var.bastion_security_group_id != null && var.node_ssh_key_name != null ? [1] : []
    content {
      ec2_ssh_key               = var.node_ssh_key_name
      source_security_group_ids = [var.bastion_security_group_id]
    }
  }

  tags = merge(var.tags, {
    NodeGroup = "main-application"
  })

  depends_on = [
    aws_iam_role_policy_attachment.nodes_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.nodes_amazon_ec2_container_registry_read_only,
  ]
}

# EKS Node Group - General Purpose
resource "aws_eks_node_group" "general_purpose" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-general-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = local.node_config.instance_types
  disk_size       = local.node_config.disk_size
  ami_type        = var.ami_type
  capacity_type   = var.capacity_type

  scaling_config {
    desired_size = local.node_config.desired_size
    max_size     = local.node_config.max_size
    min_size     = local.node_config.min_size
  }

  update_config {
    max_unavailable = 1
  }

  # No taints for general purpose node group

  # Only allow SSH if bastion is provided
  dynamic "remote_access" {
    for_each = var.bastion_security_group_id != null && var.node_ssh_key_name != null ? [1] : []
    content {
      ec2_ssh_key               = var.node_ssh_key_name
      source_security_group_ids = [var.bastion_security_group_id]
    }
  }

  tags = merge(var.tags, {
    NodeGroup = "general-purpose"
  })

  depends_on = [
    aws_iam_role_policy_attachment.nodes_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.nodes_amazon_ec2_container_registry_read_only,
  ]
}

# EKS Add-ons
resource "aws_eks_addon" "cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = var.addon_versions.vpc_cni
  resolve_conflicts_on_create = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = var.addon_versions.coredns
  resolve_conflicts_on_create = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_eks_node_group.main_app, aws_eks_node_group.general_purpose]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = var.addon_versions.kube_proxy
  resolve_conflicts_on_create = "OVERWRITE"

  tags = var.tags
}

# Security Group Rule: Allow nodes to communicate with cluster control plane
resource "aws_security_group_rule" "nodes_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow HTTPS from worker nodes to control plane"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.addon_versions.ebs_csi
  resolve_conflicts_on_create = "OVERWRITE"

  tags = var.tags
}
