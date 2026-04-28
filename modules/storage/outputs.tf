output "samples_bucket_name" {
  description = "Name of the GCS bucket storing cloned voice samples."
  value       = google_storage_bucket.samples.name
}

output "outputs_bucket_name" {
  description = "Name of the GCS bucket storing generated audio outputs."
  value       = google_storage_bucket.outputs.name
}

output "samples_bucket_url" {
  description = "URL of the GCS bucket storing cloned voice samples."
  value       = google_storage_bucket.samples.url
}

output "outputs_bucket_url" {
  description = "URL of the GCS bucket storing generated audio outputs."
  value       = google_storage_bucket.outputs.url
}
