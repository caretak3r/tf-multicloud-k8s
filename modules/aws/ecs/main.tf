# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_in_days

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
  count     = length(var.secrets) > 0 ? 1 : 0
  secret_id = aws_secretsmanager_secret.app_secrets[0].id
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
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode(concat(
    var.enable_secrets_sidecar ? [
      {
        name  = "secrets-sidecar"
        image = var.secrets_sidecar_image
        essential = false
        portMappings = [
          {
            containerPort = 8080
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
        portMappings = [
          {
            containerPort = var.container_port
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