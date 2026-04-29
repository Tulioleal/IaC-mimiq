variable "project_id" {
  description = "GCP project ID that will host the remote state bucket."
  type        = string
}

variable "region" {
  description = "GCP region used by the provider for bootstrap resources."
  type        = string
}

variable "state_bucket_name" {
  description = "Globally unique GCS bucket name for OpenTofu state."
  type        = string
}

variable "state_bucket_location" {
  description = "Bucket location for remote state. Defaults to the provider region."
  type        = string
  default     = null
}

variable "storage_class" {
  description = "Storage class for the remote state bucket."
  type        = string
  default     = "STANDARD"
}

variable "labels" {
  description = "Labels applied to bootstrap resources."
  type        = map(string)
  default     = {}
}

variable "github_repository" {
  description = "GitHub repository allowed to impersonate the CI service account, in OWNER/REPO format."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must use OWNER/REPO format."
  }
}

variable "github_ref" {
  description = "Git ref allowed to authenticate through the GitHub OIDC provider."
  type        = string
  default     = "refs/heads/main"
}

variable "github_actions_service_account_id" {
  description = "Account ID for the service account impersonated by GitHub Actions."
  type        = string
  default     = "github-actions-tofu"
}

variable "github_actions_workload_identity_pool_id" {
  description = "Workload Identity Pool ID for GitHub Actions OIDC identities."
  type        = string
  default     = "github"
}

variable "github_actions_workload_identity_provider_id" {
  description = "Workload Identity Pool Provider ID for GitHub Actions OIDC."
  type        = string
  default     = "github-actions"
}

variable "github_actions_project_roles" {
  description = "Project IAM roles granted to the GitHub Actions service account for OpenTofu apply."
  type        = list(string)
  default = [
    "roles/artifactregistry.admin",
    "roles/cloudsql.admin",
    "roles/compute.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
    "roles/run.admin",
    "roles/servicenetworking.networksAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
  ]
}

variable "frontend_github_repository" {
  description = "Optional GitHub frontend repository allowed to impersonate the frontend CI service account, in OWNER/REPO format. Leave null until the repo exists."
  type        = string
  default     = null

  validation {
    condition     = var.frontend_github_repository == null || can(regex("^[^/]+/[^/]+$", var.frontend_github_repository))
    error_message = "frontend_github_repository must use OWNER/REPO format when set."
  }
}

variable "frontend_github_ref" {
  description = "Git ref allowed to authenticate through the frontend GitHub OIDC provider."
  type        = string
  default     = "refs/heads/main"
}

variable "frontend_github_actions_service_account_id" {
  description = "Account ID for the service account impersonated by the frontend GitHub Actions workflow."
  type        = string
  default     = "github-actions-frontend"
}

variable "frontend_github_actions_workload_identity_provider_id" {
  description = "Workload Identity Pool Provider ID for the frontend GitHub Actions OIDC provider."
  type        = string
  default     = "github-actions-frontend"
}

variable "frontend_github_actions_project_roles" {
  description = "Project IAM roles granted to the frontend GitHub Actions service account."
  type        = list(string)
  default = [
    "roles/artifactregistry.writer",
  ]
}
