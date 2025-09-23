# EC2 ECS Configuration Example
cloud_provider = "aws"
aws_region     = "us-east-1"
cluster_name   = "my-ec2-cluster"
environment    = "dev"
node_size_config = "small"

# Enable ECS with EC2
enable_ecs = true
ecs_launch_type = "EC2"
ecs_container_image = "nginx:latest"
ecs_instance_type = "t3.medium"
ecs_key_name = "my-ec2-keypair"  # Optional: Specify your EC2 key pair name for SSH access

tags = {
  Environment = "development"
  Project     = "multicloud-tf"
  LaunchType  = "ec2"
}