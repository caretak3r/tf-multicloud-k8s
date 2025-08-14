data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

# Security group for bastion host
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # Allow SSH from specified CIDR blocks only
  dynamic "ingress" {
    for_each = var.allowed_ssh_cidr_blocks
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Allow SSH from ${ingress.value}"
    }
  }

  # Restrict egress to VPC CIDR and HTTPS only
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow SSH to resources within VPC"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow HTTPS within VPC"
  }

  # Allow outbound HTTPS for package updates (through NAT Gateway)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS for package updates"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP for package updates"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-sg"
  })
}

# IAM role for bastion host
resource "aws_iam_role" "bastion" {
  name = "${var.name_prefix}-bastion-role"

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

# IAM policy for bastion host to interact with EKS
resource "aws_iam_policy" "bastion_eks_access" {
  name        = "${var.name_prefix}-bastion-eks-policy"
  description = "IAM policy for bastion host EKS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_eks_access" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_eks_access.arn
}

# Attach basic SSM policy for session manager access
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# User data script for bastion host
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = var.cluster_name
    region      = var.region
  }))
}

# Bastion host EC2 instance
resource "aws_instance" "bastion" {
  ami                     = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = var.public_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  user_data              = local.user_data

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
    Type = "bastion"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch log group for bastion logs
resource "aws_cloudwatch_log_group" "bastion" {
  name              = "/aws/ec2/bastion/${var.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}