# Performance testing environment - AWS EKS
cloud_provider   = "aws"
cluster_name     = "perf-eks-cluster"
environment      = "perf"
node_size_config = "large"
aws_region       = "us-west-2"

tags = {
  Environment = "performance"
  Project     = "kubernetes-platform"
  Team        = "qa-engineering"
  CostCenter  = "engineering"
}