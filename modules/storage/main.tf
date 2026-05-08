locals {
  samples_bucket_name = "${var.bucket_name_prefix}-samples"
  outputs_bucket_name = "${var.bucket_name_prefix}-outputs"
}

resource "google_storage_bucket" "samples" {
  project                     = var.project_id
  name                        = local.samples_bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = var.labels

  force_destroy = var.bucket_force_destroy

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = var.sample_bucket_lifecycle_age_days
    }
  }
}

resource "google_storage_bucket" "outputs" {
  project                     = var.project_id
  name                        = local.outputs_bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = var.labels

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = var.output_bucket_lifecycle_age_days
    }
  }
}
