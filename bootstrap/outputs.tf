output "state_bucket_name" {
  description = "Name of the GCS bucket that stores OpenTofu state."
  value       = google_storage_bucket.state.name
}

output "state_bucket_url" {
  description = "URL of the GCS bucket that stores OpenTofu state."
  value       = google_storage_bucket.state.url
}

output "github_actions_service_account_email" {
  description = "Service account email for GitHub Actions OpenTofu runs."
  value       = google_service_account.github_actions.email
}

output "github_actions_workload_identity_provider" {
  description = "Workload Identity Provider resource name for GitHub Actions authentication."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "frontend_github_actions_service_account_email" {
  description = "Service account email for frontend GitHub Actions runs, or null when frontend repo auth is disabled."
  value       = length(google_service_account.frontend_github_actions) > 0 ? google_service_account.frontend_github_actions[0].email : null
}

output "frontend_github_actions_workload_identity_provider" {
  description = "Workload Identity Provider resource name for frontend GitHub Actions authentication, or null when disabled."
  value       = length(google_iam_workload_identity_pool_provider.frontend_github) > 0 ? google_iam_workload_identity_pool_provider.frontend_github[0].name : null
}
