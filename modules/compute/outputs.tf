output "instance_name" {
  description = "Compute Engine instance name."
  value       = google_compute_instance.this.name
}

output "service_account_email" {
  description = "Service account email attached to the backend VM."
  value       = google_service_account.this.email
}

output "internal_ip" {
  description = "Primary internal IP of the backend VM."
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "Ephemeral external IP of the backend VM."
  value       = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}
