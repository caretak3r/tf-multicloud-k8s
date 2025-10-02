# Data source for existing VPC when create_vpc = false
data "google_compute_network" "existing" {
  count = var.create_vpc ? 0 : 1
  name  = var.vpc_name
}

# VPC Network
resource "google_compute_network" "vpc" {
  count = var.create_vpc ? 1 : 0

  name                            = "${var.name_prefix}-vpc"
  auto_create_subnetworks        = false
  enable_ula_internal_ipv6      = false
  delete_default_routes_on_create = false

  description = "VPC network for ${var.name_prefix}"
}

# Private subnets
resource "google_compute_subnetwork" "private" {
  count = var.create_vpc && var.enable_private_subnets ? length(var.regions) : 0

  name          = "${var.name_prefix}-private-${var.regions[count.index]}"
  network       = google_compute_network.vpc[0].id
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  region        = var.regions[count.index]

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, count.index + 8)
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, count.index + 16)
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Public subnets
resource "google_compute_subnetwork" "public" {
  count = var.create_vpc && var.enable_public_subnets ? length(var.regions) : 0

  name          = "${var.name_prefix}-public-${var.regions[count.index]}"
  network       = google_compute_network.vpc[0].id
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  region        = var.regions[count.index]

  private_ip_google_access = false

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud NAT Router
resource "google_compute_router" "nat_router" {
  count = var.create_vpc && var.enable_nat_gateway && var.enable_private_subnets ? length(var.regions) : 0

  name    = "${var.name_prefix}-nat-router-${var.regions[count.index]}"
  network = google_compute_network.vpc[0].id
  region  = var.regions[count.index]

  bgp {
    asn = 64514
  }
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  count = var.create_vpc && var.enable_nat_gateway && var.enable_private_subnets ? length(var.regions) : 0

  name                               = "${var.name_prefix}-nat-${var.regions[count.index]}"
  router                             = google_compute_router.nat_router[count.index].name
  region                             = var.regions[count.index]
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private[count.index].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules for internal communication
resource "google_compute_firewall" "allow_internal" {
  count = var.create_vpc ? 1 : 0

  name    = "${var.name_prefix}-allow-internal"
  network = google_compute_network.vpc[0].name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
  priority      = 1000
}

# Firewall rule for health checks
resource "google_compute_firewall" "allow_health_checks" {
  count = var.create_vpc ? 1 : 0

  name    = "${var.name_prefix}-allow-health-checks"
  network = google_compute_network.vpc[0].name

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  priority      = 1000
}

# Private Service Connection for Google APIs
resource "google_compute_global_address" "private_service_connection" {
  count = var.create_vpc && var.enable_private_google_access ? 1 : 0

  name          = "${var.name_prefix}-private-service-connection"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc[0].id
}

# Service Networking Connection for Private Google Access
resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.create_vpc && var.enable_private_google_access ? 1 : 0

  network                 = google_compute_network.vpc[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_connection[0].name]
}