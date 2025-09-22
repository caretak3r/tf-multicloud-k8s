# Production environment - AWS EKS
cloud_provider   = "aws"
cluster_name     = "prod-eks-cluster"
environment      = "prod"
node_size_config = "large"
aws_region       = "us-west-2"

tags = {
  Environment = "production"
  Project     = "kubernetes-platform"
  Team        = "platform-engineering"
  CostCenter  = "production"
  Backup      = "required"
}