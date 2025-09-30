# Development environment - Azure AKS
cloud_provider      = "azure"
cluster_name        = "dev-aks-cluster"
environment         = "dev"
node_size_config    = "small"
resource_group_name = "dev-k8s-rg"
location            = "East US"

tags = {
  Environment = "dev"
  Project     = "kubernetes-platform"
  Team        = "platform-engineering"
  CostCenter  = "engineering"
}