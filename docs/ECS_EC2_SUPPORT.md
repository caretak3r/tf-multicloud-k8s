# ECS EC2 Support Documentation

This document describes the EC2 support for ECS in the multicloud-tf module.

## Overview

The ECS module now supports both Fargate and EC2 launch types. You can choose between them using the `ecs_launch_type` variable.

## Launch Types

### Fargate (Default)
- Serverless container hosting
- No EC2 instance management required
- Pay for vCPU and memory resources used by your tasks
- Suitable for workloads that don't require persistent storage or specific instance types

### EC2
- Container hosting on EC2 instances that you manage
- Full control over the underlying infrastructure
- More cost-effective for consistently running workloads
- Supports instance storage, custom AMIs, and specific instance types
- Requires managing the underlying EC2 infrastructure

## Configuration Variables

### Core ECS Variables
- `ecs_launch_type`: Choose between "FARGATE" (default) or "EC2"
- `ecs_container_image`: Docker image for your application
- `ecs_instance_type`: EC2 instance type (EC2 only, default: "t3.medium")
- `ecs_key_name`: EC2 key pair for SSH access (EC2 only, optional)

### EC2-Specific Variables
- `ecs_min_size`: Minimum number of EC2 instances (default: 1)
- `ecs_max_size`: Maximum number of EC2 instances (default: 3)
- `ecs_desired_capacity`: Desired number of EC2 instances (default: 2)
- `ecs_ec2_spot_price`: Maximum price for spot instances (optional)
- `ecs_ebs_volume_size`: EBS volume size in GB (default: 30)
- `ecs_ebs_volume_type`: EBS volume type (default: "gp3")
- `ecs_enable_container_insights`: Enable CloudWatch Container Insights (default: true)

## Features

### EC2 Launch Type Features
1. **Auto Scaling Group**: Automatically manages EC2 instance capacity
2. **Capacity Provider**: ECS-managed scaling based on task requirements
3. **Dynamic Port Mapping**: Allows multiple tasks on the same instance
4. **ECS-Optimized AMI**: Uses the latest Amazon ECS-optimized AMI
5. **Security Groups**: Separate security groups for EC2 instances and tasks
6. **IAM Roles**: Proper IAM roles for EC2 instances and ECS tasks
7. **CloudWatch Monitoring**: Instance and container-level monitoring
8. **Encrypted EBS Volumes**: All EBS volumes are encrypted by default

### Network Configuration
- **Fargate**: Uses `awsvpc` network mode with ENI per task
- **EC2**: Uses `bridge` network mode with dynamic port mapping

### Security
- **Fargate**: Security groups applied directly to ENIs
- **EC2**: Security groups applied to EC2 instances with port range 32768-65535 for ALB access
- **SSH Access**: Optional SSH access to EC2 instances when key pair is provided

## Example Configurations

### Fargate Configuration
```hcl
cloud_provider = "aws"
enable_ecs = true
ecs_launch_type = "FARGATE"
ecs_container_image = "nginx:latest"
```

### EC2 Configuration
```hcl
cloud_provider = "aws"
enable_ecs = true
ecs_launch_type = "EC2"
ecs_container_image = "nginx:latest"
ecs_instance_type = "t3.medium"
ecs_key_name = "my-keypair"  # Optional for SSH access
```

## Migration from Fargate to EC2

1. Update your `terraform.tfvars` or variable configuration:
   - Change `ecs_launch_type` from "FARGATE" to "EC2"
   - Add EC2-specific variables as needed
   - Optionally specify `ecs_key_name` for SSH access

2. Plan and apply the changes:
   ```bash
   terraform plan
   terraform apply
   ```

3. The migration will:
   - Create EC2 Auto Scaling Group and Launch Template
   - Create ECS Capacity Provider for EC2 instances
   - Update ECS Cluster capacity providers
   - Update ECS Service configuration
   - Create additional security groups for EC2 instances

## Cost Considerations

- **Fargate**: Pay-per-use pricing based on vCPU and memory
- **EC2**: Pay for EC2 instances whether tasks are running or not
- **EC2 with Spot**: Use spot pricing for significant cost savings (up to 70% off)

For consistently running workloads, EC2 is typically more cost-effective, especially with Reserved Instances or Spot pricing.

## Monitoring and Troubleshooting

### CloudWatch Logs
Both launch types use the same CloudWatch log groups:
- `/ecs/{cluster_name}` for ECS task logs

### CloudWatch Metrics
- Container Insights provides detailed metrics for both launch types
- EC2 launch type also provides EC2 instance metrics

### Troubleshooting EC2 Launch Type
1. Check Auto Scaling Group health
2. Verify ECS agent is running on EC2 instances
3. Check security group rules for port ranges
4. Verify IAM roles and policies
5. Check ECS capacity provider settings

## Limitations

### EC2 Launch Type Limitations
- Requires managing EC2 infrastructure
- Less isolation between tasks compared to Fargate
- Network configuration is more complex
- Requires careful security group management

### Fargate Limitations
- Higher per-vCPU/memory costs for consistent workloads
- Less flexibility in compute configuration
- No persistent instance storage

## Best Practices

1. **Use Fargate for**:
   - Development and testing environments
   - Batch jobs and sporadic workloads
   - Microservices with variable load
   - Workloads requiring strong isolation

2. **Use EC2 for**:
   - Production workloads with consistent resource usage
   - Applications requiring specific instance types
   - Workloads needing persistent instance storage
   - Cost-sensitive applications with predictable usage

3. **Security**:
   - Always use encrypted EBS volumes (enabled by default)
   - Limit SSH access with appropriate CIDR blocks
   - Use IAM roles instead of hardcoded credentials
   - Enable VPC Flow Logs for network monitoring

4. **Scaling**:
   - Configure appropriate min/max/desired capacity for EC2 Auto Scaling
   - Monitor ECS capacity provider metrics
   - Use spot instances for non-critical workloads to reduce costs