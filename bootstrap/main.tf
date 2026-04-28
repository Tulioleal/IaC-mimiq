locals {
  bucket_location = coalesce(var.state_bucket_location, var.region)

  labels = merge(
    {
      managed_by = "opentofu"
      stack      = "bootstrap"
    },
    var.labels,
  )
}

resource "google_project_service" "storage" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "state" {
  name                        = var.state_bucket_name
  location                    = local.bucket_location
  storage_class               = var.storage_class
  project                     = var.project_id
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.storage]
}
