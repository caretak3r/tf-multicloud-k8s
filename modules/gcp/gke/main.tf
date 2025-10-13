# User must provide KMS key - no automatic key creation

# Grant GKE service account access to the user-provided KMS key
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_kms_crypto_key_iam_member" "gke_sa" {
  crypto_key_id = var.database_encryption_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
}

locals {
  # Map node configurations to match AWS c5.2xlarge (8 vCPU, 16 GB RAM)
  node_size_map = {
    small = {
      machine_type       = "n2-standard-2" # 2 vCPU, 8 GB
      min_count          = 1
      max_count          = 5
      initial_node_count = 2
      disk_size_gb       = 50
      disk_type          = "pd-standard"
    }
    medium = {
      machine_type       = "n2-standard-4" # 4 vCPU, 16 GB
      min_count          = 2
      max_count          = 10
      initial_node_count = 3
      disk_size_gb       = 100
      disk_type          = "pd-standard"
    }
    large = {
      machine_type       = "n2-standard-8" # 8 vCPU, 32 GB - matches AWS c5.2xlarge
      min_count          = 3
      max_count          = 20
      initial_node_count = 5
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
    }
  }

  node_config = local.node_size_map[var.node_size_config]
}

module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"

  project_id = var.project_id
  name       = var.cluster_name
  region     = var.region

  # Network configuration - assumes existing VPC
  network           = var.network_name
  subnetwork        = var.subnetwork_name
  ip_range_pods     = var.pods_range_name
  ip_range_services = var.services_range_name

  # Private cluster configuration
  enable_private_endpoint = true
  enable_private_nodes    = true
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block

  # Kubernetes version and release channel
  kubernetes_version = var.kubernetes_version
  release_channel    = var.release_channel

  # Monitoring and logging
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Node pool configuration
  node_pools = [
    {
      name               = "${var.cluster_name}-main-pool"
      machine_type       = local.node_config.machine_type
      min_count          = local.node_config.min_count
      max_count          = local.node_config.max_count
      initial_node_count = local.node_config.initial_node_count
      disk_size_gb       = local.node_config.disk_size_gb
      disk_type          = local.node_config.disk_type
      auto_repair        = true
      auto_upgrade       = true
    },
    {
      name               = "${var.cluster_name}-general-pool"
      machine_type       = local.node_config.machine_type
      min_count          = local.node_config.min_count
      max_count          = local.node_config.max_count
      initial_node_count = local.node_config.initial_node_count
      disk_size_gb       = local.node_config.disk_size_gb
      disk_type          = local.node_config.disk_type
      auto_repair        = true
      auto_upgrade       = true
    }
  ]

  # Node pool OAuth scopes
  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  # Node pool labels
  node_pools_labels = {
    all = merge(var.labels, {
      cluster_name = var.cluster_name
    })
    "${var.cluster_name}-main-pool" = merge(var.labels, {
      cluster_name = var.cluster_name
      node_pool    = "main-application"
    })
    "${var.cluster_name}-general-pool" = merge(var.labels, {
      cluster_name = var.cluster_name
      node_pool    = "general-purpose"
    })
  }

  # Node pool taints
  node_pools_taints = {
    "${var.cluster_name}-main-pool"    = var.main_node_taints
    "${var.cluster_name}-general-pool" = []
  }

  # Node pool tags
  node_pools_tags = {
    all = [
      var.cluster_name,
      "gke-node",
      "private"
    ]
  }

  # Cluster resource labels
  cluster_resource_labels = merge(var.labels, {
    cluster_name = var.cluster_name
    environment  = "private"
  })

  # Database encryption with Cloud KMS
  database_encryption = [
    {
      state    = "ENCRYPTED"
      key_name = var.database_encryption_key_name
    }
  ]
}

# Create IAM binding for masters group if provided
resource "google_project_iam_member" "cluster_admin" {
  count   = var.masters_group_email != "" ? 1 : 0
  project = var.project_id
  role    = "roles/container.clusterAdmin"
  member  = "group:${var.masters_group_email}"
}

# Create firewall rules for private GKE access if needed
resource "google_compute_firewall" "gke_master_to_nodes" {
  name    = "${var.cluster_name}-master-to-nodes"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }

  source_ranges = [var.master_ipv4_cidr_block]
  target_tags   = ["gke-${var.cluster_name}"]
}
