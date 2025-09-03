# Secure ECS Deployment Guide

This guide walks you through deploying a secure ECS cluster with ALB, secrets management, and TLS configuration using the provided scripts and configuration files.

## Architecture Overview

```
Internet --> ALB (Port 443) --> ECS Service (Port 50051)
                                 |
                                 +-- Main Application Container (Port 50051)
                                 +-- Secrets Broker Sidecar (Port 8080)
```

### Key Components

- **Main Service**: Runs on port 50051, accessible via ALB on port 443
- **Secrets Broker**: Sidecar container on port 8080 for secure secret access
- **TLS Communication**: Inter-container TLS using certificates from AWS Secrets Manager
- **Existing VPC**: Deploys into your existing VPC infrastructure

## Prerequisites

- AWS CLI installed and configured with appropriate permissions
- Terraform installed (version 0.14+ recommended)
- OpenSSL installed for certificate generation
- Existing VPC with public and private subnets
- Domain name and ACM certificate (optional, for production)

## Required AWS Permissions

Your AWS credentials need the following permissions:
- EC2: Full access for key pairs and VPC resources
- ECS: Full access for cluster and service management
- Secrets Manager: Create, read, update secrets
- Application Load Balancer: Create and manage ALBs
- IAM: Create roles and policies for ECS tasks
- CloudWatch: Create log groups and streams

## Quick Start

### Step 1: Prepare Scripts

All scripts are provided in the `examples/` directory:

```bash
cd examples/
ls -la *.sh
# Should show: create-keypair.sh, generate-certs.sh, upload-secrets.sh
```

### Step 2: Generate EC2 Key Pair

Create a secure 4096-bit RSA key pair for EC2 access:

```bash
./create-keypair.sh
```

This script will:
- Generate a 4096-bit RSA private key (encrypted with AES-256)
- Extract the corresponding public key
- Import the key pair to AWS EC2
- Create a backup copy

**Important**: You'll be prompted for a passphrase to encrypt the private key. Remember this passphrase!

### Step 3: Generate TLS Certificates

Create SSL certificates for inter-container communication:

```bash
./generate-certs.sh
```

This script will:
- Prompt for certificate details (country, organization, etc.)
- Generate a private key and self-signed certificate
- Create certificate bundles
- Upload all certificates to AWS Secrets Manager

### Step 4: Upload Application Secrets

Upload your product and platform credentials:

```bash
./upload-secrets.sh
```

The script will prompt for:
- Product Client ID
- Product Secret Key
- Platform Client ID  
- Platform Secret Key

Optionally, it can generate additional secrets:
- Database URL (placeholder)
- Redis Password
- JWT Signing Key
- Encryption Key

### Step 5: Configure Terraform Variables

Copy and customize the example configuration:

```bash
cp aws-ecs-secure-deployment.tfvars my-deployment.tfvars
```

Edit `my-deployment.tfvars` and update the following required values:

```hcl
# Your AWS region
aws_region = "us-west-2"

# Your existing VPC ID
existing_vpc_id = "vpc-0123456789abcdef0"

# Your existing subnet IDs
existing_private_subnet_ids = [
  "subnet-0123456789abcdef0",  # Private subnet 1
  "subnet-0fedcba9876543210"   # Private subnet 2
]

existing_public_subnet_ids = [
  "subnet-0abcdef0123456789",  # Public subnet 1
  "subnet-09876543210fedcba"   # Public subnet 2
]

# Your container image
ecs_container_image = "your-account.dkr.ecr.us-west-2.amazonaws.com/your-app:latest"

# ACM certificate ARN (if you have one)
ecs_acm_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/your-cert-id"
```

### Step 6: Deploy Infrastructure

Initialize and apply Terraform:

```bash
terraform init
terraform plan -var-file="my-deployment.tfvars"
terraform apply -var-file="my-deployment.tfvars"
```

## Configuration Details

### Secrets Management

All secrets are stored in AWS Secrets Manager under the prefix `secure-app/prod/`:

| Secret Path | Description |
|-------------|-------------|
| `/secure-app/prod/product_client_id` | Product service client ID |
| `/secure-app/prod/product_secret_key` | Product service secret key |
| `/secure-app/prod/platform_client_id` | Platform service client ID |
| `/secure-app/prod/platform_secret_key` | Platform service secret key |
| `/secure-app/prod/ssl_certificate` | TLS certificate for inter-container communication |
| `/secure-app/prod/ssl_private_key` | TLS private key |
| `/secure-app/prod/ssl_certificate_bundle` | Combined certificate and key |

### Accessing Secrets in Your Application

The secrets broker sidecar runs on port 8080 and provides these endpoints:

```bash
# Get individual secret
curl http://localhost:8080/secrets/product_client_id

# Get all secrets as JSON
curl http://localhost:8080/secrets

# Health check
curl http://localhost:8080/health

# Get SSL certificate
curl http://localhost:8080/certificate
```

### Example Application Code

**Node.js:**
```javascript
const fetch = require('node-fetch');

async function getSecret(secretName) {
  const response = await fetch(`http://localhost:8080/secrets/${secretName}`);
  return await response.text();
}

// Usage
const productClientId = await getSecret('product_client_id');
```

**Python:**
```python
import requests

def get_secret(secret_name):
    response = requests.get(f'http://localhost:8080/secrets/{secret_name}')
    return response.text

# Usage
product_client_id = get_secret('product_client_id')
```

**Go:**
```go
import (
    "fmt"
    "io/ioutil"
    "net/http"
)

func getSecret(secretName string) (string, error) {
    resp, err := http.Get(fmt.Sprintf("http://localhost:8080/secrets/%s", secretName))
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    
    body, err := ioutil.ReadAll(resp.Body)
    return string(body), err
}
```

## Security Best Practices

### 1. Key Management
- Store private keys securely and never commit to version control
- Use strong passphrases for encrypted private keys
- Rotate keys regularly (recommend every 90 days)
- Use AWS Systems Manager Session Manager instead of SSH when possible

### 2. Secrets Management
- Use least-privilege IAM policies for secret access
- Enable AWS CloudTrail for secrets access logging
- Implement secret rotation for long-lived credentials
- Never log secret values in application logs

### 3. Network Security
- Use private subnets for ECS tasks
- Configure security groups with minimal required access
- Enable VPC Flow Logs for network monitoring
- Consider using AWS PrivateLink for service-to-service communication

### 4. Certificate Management
- Use ACM certificates for public-facing services
- Implement certificate rotation before expiry
- Monitor certificate expiration dates
- Use strong cipher suites and TLS 1.2+

## Troubleshooting

### Common Issues

**1. Key pair generation fails:**
```bash
# Check OpenSSL installation
openssl version

# Verify AWS CLI configuration
aws sts get-caller-identity
```

**2. Certificate upload fails:**
```bash
# Check AWS permissions
aws secretsmanager list-secrets --region us-west-2

# Verify certificate format
openssl x509 -in ssl_certificate.pem -text -noout
```

**3. ECS tasks fail to start:**
```bash
# Check ECS service events
aws ecs describe-services --cluster secure-app --services secure-app-service

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/secure-app"
```

**4. Secrets broker not accessible:**
- Verify both containers are in the same task definition
- Check security group rules allow port 8080
- Ensure secrets sidecar is enabled in tfvars

### Debugging Steps

1. **Verify AWS Resources:**
   ```bash
   # Check if secrets exist
   aws secretsmanager list-secrets --region us-west-2 | grep secure-app
   
   # Check ECS cluster
   aws ecs describe-clusters --clusters secure-app
   
   # Check ALB
   aws elbv2 describe-load-balancers --names secure-app-alb
   ```

2. **Check ECS Task Logs:**
   ```bash
   # Get running tasks
   aws ecs list-tasks --cluster secure-app --service-name secure-app-service
   
   # Describe specific task
   aws ecs describe-tasks --cluster secure-app --tasks <task-arn>
   ```

3. **Validate Networking:**
   ```bash
   # Check VPC and subnets
   aws ec2 describe-vpcs --vpc-ids vpc-0123456789abcdef0
   aws ec2 describe-subnets --subnet-ids subnet-0123456789abcdef0
   
   # Check security groups
   aws ec2 describe-security-groups --group-names secure-app-ecs-sg
   ```

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file="my-deployment.tfvars"
```

**Note**: This will not delete secrets from AWS Secrets Manager. Delete them manually if needed:

```bash
aws secretsmanager delete-secret --secret-id secure-app/prod/product_client_id --force-delete-without-recovery
# Repeat for all secrets
```

## Support

For issues with this deployment:

1. Check the Terraform documentation
2. Review AWS ECS and Secrets Manager documentation
3. Verify AWS permissions and quotas
4. Check CloudWatch logs for detailed error messages

## Security Considerations

- All secrets are encrypted at rest in AWS Secrets Manager
- Inter-container communication uses TLS encryption
- ECS tasks run with minimal IAM permissions
- Network access is restricted to required ports only
- All components follow AWS security best practices

This deployment provides a secure, production-ready foundation for containerized applications with comprehensive secrets management and TLS communication.