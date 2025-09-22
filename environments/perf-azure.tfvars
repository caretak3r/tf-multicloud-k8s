# Performance testing environment - Azure AKS
cloud_provider      = "azure"
cluster_name        = "perf-aks-cluster"
environment         = "perf"
node_size_config    = "large"
resource_group_name = "perf-k8s-rg"
location           = "East US"

tags = {
  Environment = "performance"
  Project     = "kubernetes-platform"
  Team        = "qa-engineering"
  CostCenter  = "engineering"
}