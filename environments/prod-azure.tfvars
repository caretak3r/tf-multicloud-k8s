# Production environment - Azure AKS
cloud_provider      = "azure"
cluster_name        = "prod-aks-cluster"
environment         = "prod"
node_size_config    = "large"
resource_group_name = "prod-k8s-rg"
location            = "East US"

tags = {
  Environment = "production"
  Project     = "kubernetes-platform"
  Team        = "platform-engineering"
  CostCenter  = "production"
  Backup      = "required"
}