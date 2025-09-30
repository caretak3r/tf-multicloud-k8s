locals {
  # Configuration map for EC2 instance types (same as EKS)
  node_size_map = {
    small = {
      instance_type    = "c5.large"
      desired_capacity = 2
      min_size         = 1
      max_size         = 5
      disk_size        = 20
    }
    medium = {
      instance_type    = "c5.xlarge"
      desired_capacity = 3
      min_size         = 2
      max_size         = 10
      disk_size        = 30
    }
    large = {
      instance_type    = "c5.2xlarge"
      desired_capacity = 5
      min_size         = 3
      max_size         = 20
      disk_size        = 50
    }
  }

  # Use node_size_config if no explicit values provided
  node_config = var.launch_type == "EC2" ? local.node_size_map[var.node_size_config] : {}

  # Final configuration (explicit values override node_size_config)
  final_instance_type    = var.launch_type == "EC2" ? (var.instance_type != null ? var.instance_type : local.node_config.instance_type) : null
  final_desired_capacity = var.launch_type == "EC2" ? (var.desired_capacity != null ? var.desired_capacity : local.node_config.desired_capacity) : null
  final_min_size         = var.launch_type == "EC2" ? (var.min_size != null ? var.min_size : local.node_config.min_size) : null
  final_max_size         = var.launch_type == "EC2" ? (var.max_size != null ? var.max_size : local.node_config.max_size) : null
  final_disk_size        = var.launch_type == "EC2" ? (var.ebs_volume_size != null ? var.ebs_volume_size : local.node_config.disk_size) : null
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = var.tags
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  capacity_providers = var.launch_type == "FARGATE" ? [
    "FARGATE", "FARGATE_SPOT"
    ] : [
    aws_ecs_capacity_provider.ec2[0].name
  ]

  dynamic "default_capacity_provider_strategy" {
    for_each = var.launch_type == "FARGATE" ? [1] : []
    content {
      base              = 1
      weight            = 100
      capacity_provider = "FARGATE"
    }
  }

  dynamic "default_capacity_provider_strategy" {
    for_each = var.launch_type == "EC2" ? [1] : []
    content {
      base              = 1
      weight            = 100
      capacity_provider = aws_ecs_capacity_provider.ec2[0].name
    }
  }

  depends_on = [aws_ecs_capacity_provider.ec2]
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

# Data source for latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  count       = var.launch_type == "EC2" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for ECS EC2 Instances
resource "aws_security_group" "ecs_instances" {
  count       = var.launch_type == "EC2" ? 1 : 0
  name_prefix = "${var.cluster_name}-ecs-instances-"
  vpc_id      = var.vpc_id

  # Allow SSH access if key pair is provided
  dynamic "ingress" {
    for_each = var.key_name != null ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
    }
  }

  # Allow traffic from ALB (will be configured via security group rules in main module)
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Allow dynamic port mapping range for ALB
  ingress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-instances"
  })
}

# IAM Role for ECS EC2 Instances
resource "aws_iam_role" "ecs_instance_role" {
  count       = var.launch_type == "EC2" ? 1 : 0
  name_prefix = "${var.cluster_name}-ecs-instance-"

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

# Attach AWS managed policy for ECS instance
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  count      = var.launch_type == "EC2" ? 1 : 0
  role       = aws_iam_role.ecs_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# IAM Instance Profile for ECS instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  count       = var.launch_type == "EC2" ? 1 : 0
  name_prefix = "${var.cluster_name}-ecs-instance-"
  role        = aws_iam_role.ecs_instance_role[0].name

  tags = var.tags
}

# Launch Template for ECS EC2 instances
resource "aws_launch_template" "ecs_instances" {
  count         = var.launch_type == "EC2" ? 1 : 0
  name_prefix   = "${var.cluster_name}-ecs-"
  image_id      = data.aws_ami.ecs_optimized[0].id
  instance_type = local.final_instance_type

  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.ecs_instances[0].id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile[0].name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = local.final_disk_size
      volume_type           = var.ebs_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = var.cluster_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-ecs-instance"
    })
  }

  tags = var.tags
}

# Auto Scaling Group for ECS EC2 instances
resource "aws_autoscaling_group" "ecs_instances" {
  count               = var.launch_type == "EC2" ? 1 : 0
  name                = "${var.cluster_name}-ecs-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = local.final_min_size
  max_size            = local.final_max_size
  desired_capacity    = local.final_desired_capacity

  launch_template {
    id      = aws_launch_template.ecs_instances[0].id
    version = "$Latest"
  }

  # Enable instance protection from scale in
  protect_from_scale_in = true

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# ECS Capacity Provider for EC2
resource "aws_ecs_capacity_provider" "ec2" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.cluster_name}-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_instances[0].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 5
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = var.tags
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.cluster_name}-ecs-tasks-"
  vpc_id      = var.vpc_id

  # Allow traffic from ALB (will be configured via security group rules in main module)
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Allow localhost communication for sidecar (only when enabled)
  dynamic "ingress" {
    for_each = var.enable_secrets_sidecar ? [1] : []
    content {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["127.0.0.1/32"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-tasks"
  })
}

# Data source for VPC CIDR
data "aws_vpc" "main" {
  id = var.vpc_id
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = "${var.cluster_name}-ecs-execution-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (application runtime)
resource "aws_iam_role" "ecs_task_role" {
  name_prefix = "${var.cluster_name}-ecs-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Secrets Manager access
resource "aws_iam_role_policy" "secrets_access" {
  name_prefix = "${var.cluster_name}-secrets-access-"
  role        = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:*:secret:${var.secrets_prefix}*"
      }
    ]
  })
}

# Secrets Manager Secret for application secrets
resource "aws_secretsmanager_secret" "app_secrets" {
  count       = length(var.secrets) > 0 ? 1 : 0
  name        = "${var.secrets_prefix}app-secrets"
  description = "Application secrets for ${var.cluster_name}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  count         = length(var.secrets) > 0 ? 1 : 0
  secret_id     = aws_secretsmanager_secret.app_secrets[0].id
  secret_string = jsonencode(var.secrets)
}

# Self-signed certificate resources (when ACM certificate not provided)
resource "tls_private_key" "self_signed" {
  count     = var.create_self_signed_cert ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed" {
  count           = var.create_self_signed_cert ? 1 : 0
  private_key_pem = tls_private_key.self_signed[0].private_key_pem

  subject {
    common_name  = var.domain_name != null ? var.domain_name : "${var.cluster_name}.local"
    organization = "Self-Signed Certificate"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Upload self-signed certificate to ACM
resource "aws_acm_certificate" "self_signed" {
  count            = var.create_self_signed_cert ? 1 : 0
  private_key      = tls_private_key.self_signed[0].private_key_pem
  certificate_body = tls_self_signed_cert.self_signed[0].cert_pem

  tags = var.tags
}

# Store certificate in Secrets Manager for container access
resource "aws_secretsmanager_secret" "certificate" {
  count       = var.create_self_signed_cert ? 1 : 0
  name        = "${var.secrets_prefix}certificate"
  description = "Self-signed certificate for ${var.cluster_name}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "certificate" {
  count     = var.create_self_signed_cert ? 1 : 0
  secret_id = aws_secretsmanager_secret.certificate[0].id
  secret_string = jsonencode({
    certificate = tls_self_signed_cert.self_signed[0].cert_pem
    private_key = tls_private_key.self_signed[0].private_key_pem
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = var.cluster_name
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  requires_compatibilities = [var.launch_type]

  # CPU and memory are only required for Fargate
  cpu    = var.launch_type == "FARGATE" ? var.task_cpu : null
  memory = var.launch_type == "FARGATE" ? var.task_memory : null

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode(concat(
    var.enable_secrets_sidecar ? [
      {
        name      = "secrets-sidecar"
        image     = var.secrets_sidecar_image
        essential = false
        cpu       = var.launch_type == "EC2" ? 256 : null
        memory    = var.launch_type == "EC2" ? 512 : null
        portMappings = [
          {
            containerPort = 8080
            hostPort      = var.launch_type == "EC2" ? 0 : 8080
            protocol      = "tcp"
          }
        ]
        environment = [
          {
            name  = "AWS_REGION"
            value = var.region
          },
          {
            name  = "SECRETS_PREFIX"
            value = var.secrets_prefix
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
            awslogs-region        = var.region
            awslogs-stream-prefix = "secrets-sidecar"
          }
        }
        healthCheck = {
          command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
          interval    = 30
          timeout     = 5
          retries     = 3
          startPeriod = 60
        }
      }
    ] : [],
    [
      {
        name      = "app"
        image     = var.container_image
        essential = true
        cpu       = var.launch_type == "EC2" ? var.task_cpu : null
        memory    = var.launch_type == "EC2" ? var.task_memory : null
        portMappings = [
          {
            containerPort = var.container_port
            hostPort      = var.launch_type == "EC2" ? 0 : var.container_port
            protocol      = "tcp"
          }
        ]
        environment = var.enable_secrets_sidecar ? concat(
          [
            {
              name  = "SECRETS_ENDPOINT"
              value = "http://localhost:8080"
            }
          ],
          var.environment_variables
        ) : var.environment_variables
        dependsOn = var.enable_secrets_sidecar ? [
          {
            containerName = "secrets-sidecar"
            condition     = "HEALTHY"
          }
        ] : []
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
            awslogs-region        = var.region
            awslogs-stream-prefix = "app"
          }
        }
      }
    ]
  ))

  tags = var.tags
}

# Note: ECS Service is created in the main module to avoid circular dependency with ALB