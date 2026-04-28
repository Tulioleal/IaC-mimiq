locals {
  bucket_location = coalesce(var.state_bucket_location, var.region)

  required_services = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ])

  labels = merge(
    {
      managed_by = "opentofu"
      stack      = "bootstrap"
    },
    var.labels,
  )
}

moved {
  from = google_project_service.storage
  to   = google_project_service.required["storage.googleapis.com"]
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_storage_bucket" "state" {
  name                        = var.state_bucket_name
  location                    = local.bucket_location
  storage_class               = var.storage_class
  project                     = var.project_id
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.required]
}

resource "google_service_account" "github_actions" {
  project      = var.project_id
  account_id   = var.github_actions_service_account_id
  display_name = "GitHub Actions OpenTofu CI"
  description  = "Service account impersonated by GitHub Actions to run OpenTofu."

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.github_actions_workload_identity_pool_id
  display_name              = "GitHub Actions"
  description               = "OIDC identities from GitHub Actions."

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.github_actions_workload_identity_provider_id
  display_name                       = "GitHub Actions OIDC"
  description                        = "OIDC provider for ${var.github_repository} GitHub Actions workflows on main."

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.ref"              = "assertion.ref"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.ref == '${var.github_ref}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_actions_workload_identity_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

resource "google_storage_bucket_iam_member" "github_actions_state_object_admin" {
  bucket = google_storage_bucket.state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions" {
  for_each = toset(var.github_actions_project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}
