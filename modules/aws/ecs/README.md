# AWS ECS Module

This module creates a secure AWS ECS (Elastic Container Service) cluster with Fargate launch type, including:

- ECS cluster with Container Insights enabled
- Secure task definition with secrets management sidecar
- IAM roles with least-privilege permissions
- CloudWatch logging
- Self-signed certificate generation and management
- Integration with Application Load Balancer

## Features

### Security
- **Fargate Launch Type**: No EC2 instances to manage, built-in isolation
- **Least Privilege IAM**: Separate execution and task roles with minimal permissions
- **Secrets Management**: Dedicated sidecar container for secure secret access
- **Network Security**: Private subnets, security groups with minimal access
- **Certificate Management**: Self-signed certificates stored in Secrets Manager

### Secrets Management
The module includes a Python-based secrets manager sidecar that:
- Runs alongside your application container
- Provides REST API access to AWS Secrets Manager
- Handles certificate storage and retrieval
- Runs as non-root for enhanced security

## Usage

```hcl
module "ecs" {
  source = "./modules/aws/ecs"

  cluster_name       = "my-app"
  vpc_id            = "vpc-123456"
  private_subnet_ids = ["subnet-123", "subnet-456"]
  region            = "us-west-2"
  
  # Container Configuration
  container_image = "my-app:latest"
  container_port  = 8000
  
  # Secrets
  secrets_prefix = "myapp/"
  secrets = {
    database_url = "postgresql://..."
    api_key     = "secret-key"
  }
  
  # Certificate (optional - will create self-signed if not provided)
  # acm_certificate_arn = "arn:aws:acm:..."
  
  tags = {
    Environment = "production"
  }
}
```

## Accessing Secrets from Your Container

Your application container can access secrets via the sidecar:

```bash
# Get entire secret
curl http://localhost:8080/secret/database-credentials

# Get specific key from JSON secret  
curl http://localhost:8080/secret/database-credentials/password

# Get certificate
curl http://localhost:8080/secret/certificate
```

## Certificate Handling

The module supports two certificate modes:

1. **Existing ACM Certificate**: Provide `acm_certificate_arn`
2. **Self-Signed Certificate**: Automatically generated and stored in Secrets Manager

Self-signed certificates are stored in Secrets Manager with both the certificate and private key, accessible via the secrets sidecar.

## Requirements

- AWS provider configured with appropriate permissions
- VPC with private subnets
- Docker images pushed to accessible registry (ECR, Docker Hub, etc.)

## Security Considerations

- Tasks run in private subnets only
- All secrets access goes through the sidecar container
- IAM roles follow principle of least privilege
- Container Insights enabled for monitoring
- All communications encrypted (HTTPS for ALB, localhost for sidecar)