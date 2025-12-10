# Air-Gapped EKS Architecture Documentation

## Detailed VPC Endpoint Requirements for Air-Gapped EKS

Based on analysis of the existing VPC endpoint implementation in `modules/aws/vpc/main.tf`, the following comprehensive endpoint strategy is required for fully air-gapped EKS deployments.

### Current VPC Endpoints Implementation
Existing module provides these endpoints when `enable_vpc_endpoints = true`:

#### Gateway Endpoints
- `s3` - Amazon S3 (Gateway type)

#### Interface Endpoints
- `ecr_dkr` - Amazon ECR Docker Registry
- `ecr_api` - Amazon ECR API
- `eks` - Amazon EKS
- `ec2` - Amazon EC2
- `logs` - Amazon CloudWatch Logs
- `sts` - AWS Security Token Service
- `elasticloadbalancing` - Elastic Load Balancing
- `autoscaling` - EC2 Auto Scaling
- `kms` - AWS Key Management Service
- `secretsmanager` - AWS Secrets Manager
- `ssm` - AWS Systems Manager
- `ssmmessages` - SSM Messages
- `ec2messages` - EC2 Messages

### Additional Endpoints Required for Air-Gapped Operations

#### Monitoring & Observability Endpoints
```hcl
resource "aws_vpc_endpoint" "monitoring" {
  count               = var.cluster_type == "airgap" && var.create_vpc ? 1 : 0
  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "application_autoscaling" {
  count               = var.cluster_type == "airgap" && var.create_vpc ? 1 : 0
  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.application-autoscaling"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
}
```

#### Security & Compliance Endpoints
```hcl
resource "aws_vpc_endpoint" "cloudtrail" {
  count               = var.cluster_type == "airgap" && var.create_vpc ? 1 : 0
  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.cloudtrail"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "events" {
  count               = var.cluster_type == "airgap" && var.create_vpc ? 1 : 0
  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.events"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
}
```

### Total Required Endpoints for Air-Gapped Deployment

| Category | Service Endpoint | Type | Purpose |
|----------|------------------|------|---------|
| **Container Registry** | ecr_dkr, ecr_api | Interface | Container image operations |
| **Kubernetes Service** | eks | Interface | EKS cluster management |
| **Compute** | ec2, ec2messages | Interface | Instance management |
| **Storage** | s3 | Gateway | Object storage access |
| **Monitoring** | logs, monitoring | Interface | Logging and metrics |
| **Security** | sts, kms, secretsmanager, cloudtrail | Interface | Authentication, encryption, secrets |
| **Management** | ssm, ssmmessages | Interface | Systems Manager operations |
| **Load Balancing** | elasticloadbalancing | Interface | Network load balancers |
| **Auto Scaling** | autoscaling, application_autoscaling | Interface | Resource scaling |
| **Events** | events | Interface | Event-driven automation |
| **Tagging** | tagging | Interface | Resource tagging operations |

**Total: 17 endpoints** (14 existing + 3 additional for air-gap)

### VPC Endpoint Security Group Configuration

Enhanced security group rules for air-gapped deployments:

```hcl
resource "aws_security_group" "vpc_endpoints_airgap" {
  count = var.create_vpc && var.cluster_type == "airgap" ? 1 : 0

  name        = "${var.name_prefix}-vpc-endpoints-airgap-sg"
  description = "Enhanced security group for air-gapped VPC endpoints"
  vpc_id      = aws_vpc.main[0].id

  # Restrict ingress to VPC CIDR only
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS access from within VPC only"
  }

  # Restrict egress to VPC CIDR for air-gap
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "VPC internal traffic only for air-gap"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc-endpoints-airgap-sg"
    Type = "airgap-endpoints"
  })
}
```

### Network Security Architecture

#### Air-Gapped Security Group Rules

EKS Cluster Security Group modifications for air-gap:

```hcl
# Enhanced cluster security group for air-gapped deployments
resource "aws_security_group" "cluster_airgap" {
  count = var.cluster_type == "airgap" ? 1 : 0

  name        = "${var.cluster_name}-cluster-airgap-sg"
  description = "Air-gapped EKS cluster security group"
  vpc_id      = var.vpc_id

  # VPN access only for kubectl (Client VPN endpoint)
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.client_vpn_security_group_id]
    description     = "kubectl access via Client VPN only"
  }

  # Bastion access for operations (if enabled)
  dynamic "ingress" {
    for_each = var.bastion_security_group_id != null ? [1] : []
    content {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [var.bastion_security_group_id]
      description     = "Operational access from bastion"
    }
  }

  # NO internet egress - VPC endpoints only
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_endpoints[0].id]
    description     = "AWS API access via VPC endpoints"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-airgap-sg"
    Type = "airgap-cluster"
  })
}
```

Node security group for air-gapped deployments:

```hcl
resource "aws_security_group" "nodes_airgap" {
  count = var.cluster_type == "airgap" ? 1 : 0

  name        = "${var.cluster_name}-nodes-airgap-sg"
  description = "Air-gapped EKS worker nodes security group"
  vpc_id      = var.vpc_id

  # Full communication within VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Full VPC internal communication"
  }

  # STRICT egress - VPC CIDR only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "VPC internal traffic only - NO INTERNET"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nodes-airgap-sg"
    Type = "airgap-nodes"
  })
}
```

### Air-Gapped Node Group Configuration

Enhanced node groups for air-gap deployments:

```hcl
# Air-Gapped General Node Group - System Components
resource "aws_eks_node_group" "general_node_group_airgap" {
  count = var.cluster_type == "airgap" ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-general-airgap"
  node_role_arn   = aws_iam_role.nodes_enhanced[0].arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = local.node_config.instance_types
  disk_size       = local.node_config.disk_size
  ami_type        = var.ami_type
  capacity_type   = var.capacity_type

  scaling_config {
    desired_size = var.cluster_type == "airgap" ? 2 : local.node_config.desired_size
    max_size     = local.node_config.max_size
    min_size     = 1
  }

  # No taints - general purpose for system components
  tags = merge(var.tags, {
    NodeGroup = "general-airgap"
    Purpose   = "system-components"
  })
}

# Air-Gapped Product Node Group - Application Workloads
resource "aws_eks_node_group" "product_node_group_airgap" {
  count = var.cluster_type == "airgap" ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-product-airgap"
  node_role_arn   = aws_iam_role.nodes_enhanced[0].arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.product_node_instance_types != null ? var.product_node_instance_types : local.node_config.instance_types
  disk_size       = local.node_config.disk_size
  ami_type        = var.ami_type
  capacity_type   = var.capacity_type

  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 1
  }

  # Product workloads with taint for isolation
  taint {
    key    = "workload-type"
    value  = "product"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.tags, {
    NodeGroup = "product-airgap"
    Purpose   = "application-workloads"
  })
}
```

### Umbrella Chart Structure for Air-Gapped Deployments

Directory structure for air-gap umbrella chart:

```
airgap-umbrella/
├── Chart.yaml
├── values.yaml
├── charts/
│   ├── monitoring/
│   │   └── Chart.yaml
│   ├── logging/
│   │   └── Chart.yaml
│   ├── security/
│   │   └── Chart.yaml
│   └── networking/
│       └── Chart.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── configmaps.yaml
│   └── rbac.yaml
└── docs/
    └── airgap-deployment.md
```

#### Sample values.yaml for air-gap configuration:

```yaml
# Air-Gapped Umbrella Chart Configuration
global:
  airgap: true
  storageClass: "gp2"
  registry: "${ECR_REPOSITORY_URL}"

monitoring:
  enabled: true
  prometheus:
    serviceMonitor: true
    storage: "20Gi"
  grafana:
    enabled: true
    adminPassword: "${GRAFANA_PASSWORD}"

logging:
  enabled: true
  elasticsearch:
    storage: "30Gi"
    replicas: 2
  kibana:
    enabled: true
    replicas: 2

security:
  enabled: true
  networkPolicy:
    enabled: true
    defaultDeny: true
  podSecurityPolicy:
    enabled: true
  rbac:
    enabled: true

networking:
  enabled: true
  ingress:
    enabled: false  # No external internet access
  serviceMesh:
    enabled: false  # Optional for air-gap environments

# Node group affinity and tolerations
nodeSelector:
  workload-type: "system"

tolerations:
- key: "workload-type"
  operator: "Equal"
  value: "product"
  effect: "NoSchedule"
```

### Deployment Flow Sequence

1. **Infrastructure Provisioning**
   ```bash
   terraform apply -var-file="airgap.tfvars" \
     -var="cluster_type=airgap" \
     -var="enable_vpc_endpoints=true"
   ```

2. **Container Image Synchronization**
   ```bash
   # From bastion host with internet access
   aws ecr create-repository --repository-name my-app
   docker pull external-registry.com/my-app:v1.0
   docker tag external-registry.com/my-app:v1.0 ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-app:v1.0
   docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-app:v1.0
   ```

3. **Umbrella Chart Deployment**
   ```bash
   # Deploy via VPN connection
   helm install airgap-umbrella ./airgap-umbrella \
     --set global.registry=${ECR_REPO} \
     --namespace airgap-system \
     --create-namespace
   ```

### Client VPN Configuration Integration

For air-gapped deployments, integrate Client VPN endpoint:

```hcl
resource "aws_ec2_client_vpn_endpoint" "airgap" {
  count             = var.cluster_type == "airgap" ? 1 : 0
  client_cidr_block = var.client_vpn_cidr
  server_certificate_arn = var.server_certificate_arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_certificate_arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn[0].name
    cloudwatch_log_stream = var.vpn_log_stream
  }

  vpc_id               = var.vpc_id
  security_group_ids   = [aws_security_group.vpn[0].id]

  tag {
    key   = "Name"
    value = "${var.cluster_name}-client-vpn"
  }
}
```

This comprehensive documentation provides the technical foundation for implementing fully air-gapped EKS environments while maintaining compatibility with existing standard deployments.
