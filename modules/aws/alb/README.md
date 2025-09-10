# AWS Application Load Balancer Module

This module creates a secure Application Load Balancer (ALB) with:

- HTTPS-only configuration with HTTP to HTTPS redirect
- Target group with health checks
- Security groups with configurable access
- Support for both internal and internet-facing deployments

## Features

### Security
- **HTTPS Enforcement**: Automatic HTTP to HTTPS redirect
- **Security Groups**: Restrictive ingress rules with configurable CIDR blocks
- **SSL/TLS**: Configurable SSL policies with secure defaults

## Usage

```hcl
module "alb" {
  source = "./modules/aws/alb"

  cluster_name       = "my-app"
  vpc_id            = "vpc-123456"
  public_subnet_ids = ["subnet-123", "subnet-456"]
  certificate_arn   = "arn:aws:acm:us-west-2:123456789012:certificate/..."
  
  # Target configuration
  target_port       = 8000
  health_check_path = "/health"
  
  # Security configuration
  allowed_cidr_blocks = ["10.0.0.0/8", "192.168.1.0/24"]
  
  tags = {
    Environment = "production"
  }
}
```

## Configuration Options

### Network Configuration
- `internal_alb`: Deploy as internal (private) or internet-facing ALB
- `allowed_cidr_blocks`: Control access with CIDR block restrictions
- `public_subnet_ids`/`private_subnet_ids`: Subnet placement

### Security Configuration  
- `ssl_policy`: SSL/TLS policy for HTTPS listener
- `enable_deletion_protection`: Prevent accidental deletion

### Health Checks
- `health_check_path`: Custom health check endpoint
- Built-in health check configuration with reasonable defaults

## Outputs

- `alb_dns_name`: DNS name for accessing the application
- `target_group_arn`: For ECS service integration
- `security_group_id`: For allowing ECS task access

## Requirements

- Valid SSL certificate (ACM or imported)
- VPC with appropriate subnets (public for internet-facing, private for internal)
- Target application that responds to health checks