# Create KMS keyring and key if not provided
resource "google_kms_key_ring" "gke" {
  count    = var.database_encryption_key_name == null ? 1 : 0
  name     = "${var.cluster_name}-keyring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "gke" {
  count           = var.database_encryption_key_name == null ? 1 : 0
  name            = "${var.cluster_name}-key"
  key_ring        = google_kms_key_ring.gke[0].id
  rotation_period = "7776000s" # 90 days
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = false
  }
}

# Grant GKE service account access to the KMS key
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_kms_crypto_key_iam_member" "gke_sa" {
  count         = var.database_encryption_key_name == null ? 1 : 0
  crypto_key_id = google_kms_crypto_key.gke[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
}

locals {
  # Determine which KMS key to use
  kms_key_name = var.database_encryption_key_name != null ? var.database_encryption_key_name : (var.database_encryption_key_name == null ? google_kms_crypto_key.gke[0].id : null)
  
  # Map node configurations to match AWS c5.2xlarge (8 vCPU, 16 GB RAM)
  node_size_map = {
    small = {
      machine_type = "n2-standard-2"  # 2 vCPU, 8 GB
      min_count    = 1
      max_count    = 5
      initial_node_count = 2
      disk_size_gb = 50
      disk_type    = "pd-standard"
    }
    medium = {
      machine_type = "n2-standard-4"  # 4 vCPU, 16 GB
      min_count    = 2
      max_count    = 10
      initial_node_count = 3
      disk_size_gb = 100
      disk_type    = "pd-standard"
    }
    large = {
      machine_type = "n2-standard-8"  # 8 vCPU, 32 GB - matches AWS c5.2xlarge
      min_count    = 3
      max_count    = 20
      initial_node_count = 5
      disk_size_gb = 100
      disk_type    = "pd-ssd"
    }
  }

  node_config = local.node_size_map[var.node_size_config]
}

# Use the terraform-google-modules/kubernetes-engine module for GKE
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 29.0"

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
  master_ipv4_cidr_block = var.master_ipv4_cidr_block

  # Master authorized networks - for admin access
  master_authorized_networks = var.master_authorized_networks

  # Kubernetes version and release channel
  kubernetes_version = var.kubernetes_version
  release_channel    = var.release_channel

  # Security features
  enable_shielded_nodes       = var.enable_shielded_nodes
  enable_binary_authorization = var.enable_binary_authorization
  workload_identity_enabled   = var.enable_workload_identity
  enable_network_policy       = var.enable_network_policy

  # RBAC configuration - Google Groups for admins
  authenticator_security_group = var.masters_group_email != "" ? var.masters_group_email : null
  rbac_group_domain            = var.rbac_group_domain

  # Monitoring and logging
  logging_enabled_components    = var.logging_enabled_components
  monitoring_enabled_components = var.monitoring_enabled_components

  # Cluster addons
  horizontal_pod_autoscaling = var.enable_horizontal_pod_autoscaling
  vertical_pod_autoscaling   = var.enable_vertical_pod_autoscaling
  filestore_csi_driver       = var.enable_filestore_csi_driver
  gcs_fuse_csi_driver       = var.enable_gcs_fuse_csi_driver

  # Disable public endpoint completely for full privacy
  deploy_using_private_endpoint = true
  
  # Enable Dataplane V2 for better network performance
  datapath_provider = "ADVANCED_DATAPATH"

  # Node pool configuration
  node_pools = [
    {
      name               = "${var.cluster_name}-node-pool"
      machine_type       = local.node_config.machine_type
      min_count          = local.node_config.min_count
      max_count          = local.node_config.max_count
      initial_node_count = local.node_config.initial_node_count
      disk_size_gb       = local.node_config.disk_size_gb
      disk_type          = local.node_config.disk_type
      auto_repair        = true
      auto_upgrade       = true
      
      # Use spot instances for cost optimization (similar to AWS spot)
      spot               = var.node_size_config != "large"
      
      # Enable workload identity for the node pool
      workload_metadata_config = var.enable_workload_identity ? "GKE_METADATA" : "UNSPECIFIED"
      
      # Preemptible instances for non-production
      preemptible        = false
      
      # Node taints and labels
      node_metadata      = "GKE_METADATA_SERVER"
      
      # Security settings
      enable_secure_boot          = var.enable_shielded_nodes
      enable_integrity_monitoring = var.enable_shielded_nodes
      
      # Service account - will be created by the module
      service_account = "default"
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
      node_pool    = "default"
    })
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

  # Configure cluster autoscaling
  cluster_autoscaling = {
    enabled             = true
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    min_cpu_cores       = local.node_config.min_count * 8  # Based on n2-standard-8
    max_cpu_cores       = local.node_config.max_count * 8
    min_memory_gb       = local.node_config.min_count * 32
    max_memory_gb       = local.node_config.max_count * 32
    gpu_resources       = []
  }

  # Maintenance window
  maintenance_start_time = "05:00"
  maintenance_end_time   = "07:00"
  maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"

  # Remove default node pool
  remove_default_node_pool = true
  
  # Database encryption with Cloud KMS
  database_encryption = [
    {
      state    = "ENCRYPTED"
      key_name = local.kms_key_name
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