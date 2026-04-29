resource "google_artifact_registry_repository" "frontend" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  description   = var.repository_description
  format        = "DOCKER"
  labels        = var.labels
}

resource "google_cloud_run_v2_service" "frontend" {
  count = var.frontend_enabled ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = var.frontend_service_name
  ingress  = "INGRESS_TRAFFIC_ALL"
  labels   = var.labels

  template {
    labels = var.labels

    containers {
      image = var.frontend_image

      ports {
        container_port = var.frontend_container_port
      }

      dynamic "env" {
        for_each = var.frontend_env

        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !var.frontend_enabled || var.frontend_image != ""
      error_message = "frontend_image must be set when frontend_enabled is true."
    }
  }

  depends_on = [google_artifact_registry_repository.frontend]
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.frontend_enabled && var.frontend_public ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.frontend[0].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
