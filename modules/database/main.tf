resource "google_sql_database_instance" "this" {
  name                = "${var.name_prefix}-postgres"
  project             = var.project_id
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_autoresize   = true
    disk_size         = var.disk_size_gb
    disk_type         = "PD_SSD"
    user_labels       = var.labels

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }

    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = false
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.private_network_self_link
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database" "app" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "app" {
  name     = var.username
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  password = var.password
}
