data "google_iam_policy" "gke_developer" {
  count = var.create_bastion ? 1 : 0
  binding {
    role = "roles/container.developer"
    members = [
      "serviceAccount:${var.create_bastion ? google_service_account.bastion[0].email : ""}",
    ]
  }
}

resource "google_project_iam_policy" "gke_developer_policy" {
  count       = var.create_bastion ? 1 : 0
  project     = var.project_id
  policy_data = data.google_iam_policy.gke_developer[0].policy_data
}

resource "google_service_account" "bastion" {
  count        = var.create_bastion ? 1 : 0
  account_id   = "${var.cluster_name}-bastion-sa"
  display_name = "Service Account for GKE Bastion Host"
  project      = var.project_id
}

resource "google_compute_instance" "bastion" {
  count        = var.create_bastion ? 1 : 0
  project      = var.project_id
  name         = "${var.cluster_name}-bastion"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["bastion"]

  boot_disk {
    initialize_params {
      image  = "debian-cloud/debian-11"
      labels = var.tags
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${join("\n", var.bastion_authorized_keys)}"
  }

  metadata_startup_script = templatefile("${path.module}/user_data.sh", {
    cluster_name = var.cluster_name
    region       = var.region
  })

  service_account {
    email  = var.create_bastion ? google_service_account.bastion[0].email : null
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  depends_on = [google_project_iam_policy.gke_developer_policy]
}
