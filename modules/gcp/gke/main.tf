# GKE Cluster using native Terraform resources
# This module creates a fully private-like GKE cluster without using external modules

locals {
  # Default service account email if create_service_account is true
  service_account_email = var.create_service_account ? google_service_account.gke_nodes[0].email : var.compute_engine_service_account

  # Determine if we should use dataplane v2
  use_advanced_datapath = var.datapath_provider == "ADVANCED_DATAPATH"
}

# Create service account for GKE nodes if needed
resource "google_service_account" "gke_nodes" {
  count      = var.create_service_account ? 1 : 0
  account_id = "${var.name}-gke-nodes"
  project    = var.project_id

  display_name = "${var.name} GKE Nodes Service Account"
  description  = "Service account for GKE nodes with minimal permissions"
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "gke_nodes_logging" {
  count   = var.create_service_account ? 1 : 0
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring" {
  count   = var.create_service_account ? 1 : 0
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_metrics" {
  count   = var.create_service_account ? 1 : 0
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

# Grant registry access if needed
resource "google_project_iam_member" "gke_nodes_registry" {
  count   = var.create_service_account && var.grant_registry_access ? 1 : 0
  project = length(var.registry_project_ids) > 0 ? var.registry_project_ids[0] : var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

# Create GKE cluster
resource "google_container_cluster" "gke_cluster" {
  provider = google

  project  = var.project_id
  name     = var.name
  location = var.region

  description         = var.description
  deletion_protection = var.deletion_protection

  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork

  # GKE Private cluster configuration
  private_cluster_config {
    enable_private_endpoint = var.enable_private_endpoint
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }

  # Release channel configuration
  release_channel {
    channel = var.release_channel
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          display_name = cidr_blocks.value.display_name
          cidr_block   = cidr_blocks.value.cidr_block
        }
      }
    }
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = !var.http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.horizontal_pod_autoscaling
    }

    network_policy_config {
      disabled = local.use_advanced_datapath
    }

    gce_persistent_disk_csi_driver_config {
      enabled = var.gce_pd_csi_driver
    }

    dns_cache_config {
      enabled = var.dns_cache
    }
  }

  # Network configuration
  network_policy {
    enabled = local.use_advanced_datapath ? false : true
  }

  # Dataplane provider
  datapath_provider = var.datapath_provider

  # Default max pods per node
  default_max_pods_per_node = var.default_max_pods_per_node

  # Database encryption
  database_encryption {
    state    = var.database_encryption[0].state
    key_name = var.database_encryption[0].key_name
  }

  # Shielded nodes
  remove_default_node_pool = true
  initial_node_count       = 1

  # Resource labels
  resource_labels = var.cluster_resource_labels

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Logging and monitoring
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service

  # Vertical pod autoscaling
  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }

  # Node configuration
  node_config {
    service_account = local.service_account_email

    # Set OAuth scopes
    oauth_scopes = var.node_pools_oauth_scopes["all"]

    # Set metadata
    metadata = var.node_pools_metadata["all"]

    # Image type
    image_type = var.sandbox_enabled ? "COS_CONTAINERD" : "COS_CONTAINERD"

    # Disk configuration
    disk_size_gb = 100
    disk_type    = "pd-standard"

    # Labels and tags
    labels = var.node_pools_labels["all"]
    tags   = var.node_pools_tags["all"]

    # Taints
    dynamic "taint" {
      for_each = var.node_pools_taints["all"]
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }
}

# Create default node pool
resource "google_container_node_pool" "default_node_pool" {
  project  = var.project_id
  name     = "default-pool"
  location = var.region
  cluster  = google_container_cluster.gke_cluster.name

  # Node count
  initial_node_count = 1

  # Node configuration
  node_config {
    machine_type    = "e2-medium"
    service_account = local.service_account_email

    # Set OAuth scopes
    oauth_scopes = var.node_pools_oauth_scopes["all"]

    # Set metadata
    metadata = var.node_pools_metadata["all"]

    # Image type
    image_type = var.sandbox_enabled ? "COS_CONTAINERD" : "COS_CONTAINERD"

    # Disk configuration
    disk_size_gb = 100
    disk_type    = "pd-standard"

    # Labels and tags
    labels = var.node_pools_labels["all"]
    tags   = var.node_pools_tags["all"]

    # Taints
    dynamic "taint" {
      for_each = var.node_pools_taints["all"]
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  # Auto-upgrade and auto-repair
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node pool upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
