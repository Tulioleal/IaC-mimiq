resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  project       = var.project_id
  name          = "${var.name_prefix}-subnet"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr
}

resource "google_compute_global_address" "private_service_range" {
  project       = var.project_id
  name          = "${var.name_prefix}-sql-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_range_prefix_length
  network       = google_compute_network.this.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]

  deletion_policy = "ABANDON"
}

resource "google_compute_firewall" "ssh" {
  project       = var.project_id
  name          = "${var.name_prefix}-allow-ssh"
  network       = google_compute_network.this.name
  source_ranges = var.ssh_source_ranges
  target_tags   = var.target_tags

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "app" {
  count = length(var.app_source_ranges) > 0 ? 1 : 0

  project       = var.project_id
  name          = "${var.name_prefix}-allow-app"
  network       = google_compute_network.this.name
  source_ranges = var.app_source_ranges
  target_tags   = var.target_tags

  allow {
    protocol = "tcp"
    ports    = var.app_ports
  }
}
