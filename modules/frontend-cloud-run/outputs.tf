output "artifact_registry_repository_id" {
  description = "Artifact Registry repository ID."
  value       = google_artifact_registry_repository.frontend.repository_id
}

output "artifact_registry_repository_url" {
  description = "Docker repository URL for frontend images."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.frontend.repository_id}"
}

output "frontend_service_name" {
  description = "Cloud Run frontend service name, or null when disabled."
  value       = var.frontend_enabled ? google_cloud_run_v2_service.frontend[0].name : null
}

output "frontend_service_url" {
  description = "Cloud Run frontend service URL, or null when disabled."
  value       = var.frontend_enabled ? google_cloud_run_v2_service.frontend[0].uri : null
}
