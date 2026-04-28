output "network_name" {
  description = "Name of the VPC network."
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "Self-link of the VPC network."
  value       = google_compute_network.this.self_link
}

output "subnetwork_name" {
  description = "Name of the primary subnetwork."
  value       = google_compute_subnetwork.this.name
}

output "subnetwork_self_link" {
  description = "Self-link of the primary subnetwork."
  value       = google_compute_subnetwork.this.self_link
}

output "service_networking_connection" {
  description = "Service Networking connection name for private Google services."
  value       = google_service_networking_connection.private_vpc_connection.peering
}
