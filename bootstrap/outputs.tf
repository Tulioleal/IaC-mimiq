output "state_bucket_name" {
  description = "Name of the GCS bucket that stores OpenTofu state."
  value       = google_storage_bucket.state.name
}

output "state_bucket_url" {
  description = "URL of the GCS bucket that stores OpenTofu state."
  value       = google_storage_bucket.state.url
}
