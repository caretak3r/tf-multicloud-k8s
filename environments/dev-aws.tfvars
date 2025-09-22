# Development environment - AWS EKS
cloud_provider   = "aws"
cluster_name     = "dev-eks-cluster"
environment      = "dev"
node_size_config = "small"
aws_region       = "us-east-1"

tags = {
  Environment = "dev"
  Project     = "kubernetes-platform"
  Team        = "platform-engineering"
  CostCenter  = "engineering"
}