# Fargate ECS Configuration Example
cloud_provider = "aws"
aws_region     = "us-east-1"
cluster_name   = "my-fargate-cluster"
environment    = "dev"
node_size_config = "small"

# Enable ECS with Fargate
enable_ecs = true
ecs_launch_type = "FARGATE"
ecs_container_image = "nginx:latest"

tags = {
  Environment = "development"
  Project     = "multicloud-tf"
  LaunchType  = "fargate"
}