output "backend_instance_name" {
  description = "Backend Compute Engine instance name."
  value       = module.compute.instance_name
}

output "backend_external_ip" {
  description = "Ephemeral public IP of the backend VM."
  value       = module.compute.external_ip
}

output "backend_internal_ip" {
  description = "Private IP of the backend VM."
  value       = module.compute.internal_ip
}

output "backend_service_account_email" {
  description = "Service account attached to the backend VM."
  value       = module.compute.service_account_email
}

output "database_private_ip" {
  description = "Private IP address of the Cloud SQL instance."
  value       = module.database.private_ip_address
}

output "database_connection_name" {
  description = "Cloud SQL connection name."
  value       = module.database.connection_name
}

output "samples_bucket_name" {
  description = "GCS bucket name used for stored voice samples."
  value       = module.storage.samples_bucket_name
}

output "outputs_bucket_name" {
  description = "GCS bucket name used for generated audio outputs."
  value       = module.storage.outputs_bucket_name
}

output "artifact_registry_repository_url" {
  description = "Docker repository URL for frontend images."
  value       = module.frontend.artifact_registry_repository_url
}

output "frontend_service_name" {
  description = "Cloud Run frontend service name, or null when disabled."
  value       = module.frontend.frontend_service_name
}

output "frontend_service_url" {
  description = "Cloud Run frontend service URL, or null when disabled."
  value       = module.frontend.frontend_service_url
}
