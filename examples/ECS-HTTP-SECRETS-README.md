# ECS HTTP Server with Secrets Sidecar Deployment Guide

This example demonstrates how to deploy an ECS cluster with two services:
1. **HTTP Server Service** - A secure HTTPS server with self-signed certificates
2. **Secrets Sidecar Service** - Fetches secrets from AWS Secrets Manager and provides them to the HTTP server

## Architecture Overview

```
Internet → ALB (HTTPS) → ECS Service
                           ├── HTTP Server Container (nginx:443)
                           └── Secrets Sidecar Container (localhost:8080)
                               └── AWS Secrets Manager
```

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** v1.0+ installed
3. **OpenSSL** for certificate generation
4. **AWS Key Pair** for bastion host access

### Required AWS Permissions

Your AWS credentials need the following permissions:
- EC2 (VPC, Subnets, Security Groups, ALB)
- ECS (Clusters, Services, Task Definitions)
- IAM (Roles, Policies)
- Secrets Manager (Create/Read secrets)
- Certificate Manager (Import certificates)
- CloudWatch (Log Groups)

## Quick Start

### 1. Clone and Navigate

```bash
cd /path/to/multicloud-tf
```

### 2. Create AWS Key Pair

```bash
# Create a new key pair (replace 'my-key-pair' with your preferred name)
aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > my-key-pair.pem
chmod 400 my-key-pair.pem
```

### 3. Generate Self-Signed Certificates

```bash
./scripts/generate-certificates.sh
```

### 4. Setup AWS Secrets Manager

```bash
./scripts/setup-secrets.sh
```

### 5. Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file="examples/ecs-http-secrets-example.tfvars"

# Deploy
terraform apply -var-file="examples/ecs-http-secrets-example.tfvars"
```

## Configuration Details

### Service Architecture

#### HTTP Server Container
- **Image**: nginx:latest (replace with your application)
- **Port**: 443 (HTTPS)
- **Resources**: 0.5 vCPU, 1GB RAM
- **Certificates**: Mounted from EFS or S3
- **Environment Variables**:
  - `SECRETS_SIDECAR_URL=http://localhost:8080`
  - `CERT_PATH=/etc/ssl/certs/server.crt`
  - `KEY_PATH=/etc/ssl/private/server.key`

#### Secrets Sidecar Container
- **Image**: amazon/aws-cli:latest (replace with your sidecar)
- **Port**: 8080 (HTTP, localhost only)
- **Purpose**: Fetch secrets from AWS Secrets Manager
- **API Endpoints**:
  - `GET /secrets/{secret-name}` - Retrieve specific secret
  - `GET /health` - Health check

### Secrets Management

The following secrets are created in AWS Secrets Manager under the `http-server/` prefix:

| Secret Name | Purpose | Example Value |
|-------------|---------|---------------|
| `database_password` | Database authentication | `my-secure-db-password` |
| `api_key` | External API access | `sk-1234567890abcdefghijklmnop` |
| `jwt_signing_key` | JWT token signing | `super-secret-jwt-key-for-token-signing` |
| `redis_password` | Redis authentication | `redis-secure-password-123` |
| `encryption_key` | Data encryption | `32-char-aes256-encryption-key!!` |
| `oauth_client_secret` | OAuth integration | `oauth-app-client-secret-value` |
| `smtp_password` | Email service | `email-service-password-secure` |
| `third_party_api_key` | 3rd party service | `3rd-party-service-api-key-123` |

### Security Features

- **VPC Isolation**: Services run in private subnets
- **Security Groups**: Restrictive ingress/egress rules
- **SSL/TLS**: End-to-end encryption with self-signed certificates
- **WAF**: Web Application Firewall with rate limiting
- **Secrets Management**: Secure secret storage and retrieval
- **Bastion Host**: Secure access for troubleshooting

## Usage Examples

### Accessing Your Service

After deployment, get the ALB DNS name:

```bash
# Get ALB DNS name
terraform output alb_dns_name

# Test the service
curl -k https://<alb-dns-name>/health
```

### Fetching Secrets (from within containers)

The HTTP server can fetch secrets from the sidecar:

```bash
# Get database password
curl http://localhost:8080/secrets/database_password

# Get API key
curl http://localhost:8080/secrets/api_key
```

### SSH Access via Bastion

```bash
# Get bastion IP
terraform output bastion_public_ip

# SSH to bastion
ssh -i my-key-pair.pem ec2-user@<bastion-ip>

# From bastion, you can access private resources
```

## Customization

### Using Your Own Images

1. **Build your HTTP server image**:
```bash
# Example Dockerfile for HTTP server
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY ssl/ /etc/ssl/
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
```

2. **Build your secrets sidecar image**:
```bash
# Example Dockerfile for secrets sidecar
FROM python:3.9-alpine
RUN pip install boto3 flask
COPY sidecar.py /app/
EXPOSE 8080
CMD ["python", "/app/sidecar.py"]
```

3. **Push to ECR**:
```bash
# Create ECR repositories
aws ecr create-repository --repository-name http-server
aws ecr create-repository --repository-name secrets-sidecar

# Push images (follow ECR push commands)
```

4. **Update tfvars**:
```hcl
ecs_container_image = "123456789012.dkr.ecr.us-west-2.amazonaws.com/http-server:latest"
ecs_secrets_sidecar_image = "123456789012.dkr.ecr.us-west-2.amazonaws.com/secrets-sidecar:latest"
```

### Environment-Specific Configuration

Create separate tfvars files for different environments:

```bash
# Development
terraform apply -var-file="examples/ecs-http-secrets-example.tfvars" -var="environment=dev"

# Staging
terraform apply -var-file="examples/ecs-http-secrets-example.tfvars" -var="environment=staging"

# Production
terraform apply -var-file="examples/ecs-http-secrets-example.tfvars" -var="environment=prod" -var="ecs_desired_count=5"
```

## Monitoring and Troubleshooting

### CloudWatch Logs

```bash
# View ECS service logs
aws logs describe-log-groups --log-group-name-prefix="/ecs/http-secrets-cluster"

# Tail logs
aws logs tail "/ecs/http-secrets-cluster" --follow
```

### ECS Service Status

```bash
# Check service status
aws ecs describe-services --cluster http-secrets-cluster --services http-secrets-cluster-with-alb

# Check task health
aws ecs describe-tasks --cluster http-secrets-cluster --tasks <task-arn>
```

### Common Issues

1. **Service not starting**: Check CloudWatch logs for container errors
2. **ALB health checks failing**: Verify health check path and port
3. **Secrets not accessible**: Check IAM roles and Secrets Manager permissions
4. **SSL certificate issues**: Verify certificate format and file paths

## Cleanup

```bash
# Destroy the infrastructure
terraform destroy -var-file="examples/ecs-http-secrets-example.tfvars"

# Clean up secrets (optional)
./scripts/cleanup-secrets.sh

# Remove certificates
rm -rf certs/
```

## Security Best Practices

1. **Restrict ALB access**: Update `ecs_allowed_cidr_blocks` to specific IPs
2. **Use ACM certificates**: Replace self-signed certificates with ACM for production
3. **Rotate secrets**: Implement secret rotation policies
4. **Monitor access**: Enable CloudTrail and VPC Flow Logs
5. **Update images**: Regularly update container images
6. **Network segmentation**: Use separate subnets for different tiers

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review CloudWatch logs
3. Verify AWS permissions
4. Submit an issue to the project repository

## Related Examples

- `aws-ecs-full-stack.tfvars` - Full stack ECS deployment
- `aws-ecs-production-ready.tfvars` - Production-ready configuration
- `aws-ecs-dual-service-concept.tfvars` - Multi-service deployment concept