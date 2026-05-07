locals {
  resource_prefix = "${var.app_name}-${var.environment}"
  network_tags    = ["${local.resource_prefix}-backend"]

  derived_frontend_backend_api_base_url = "http://${module.compute.external_ip}:${var.backend_service_port}"
  derived_frontend_public_ws_base_url   = "ws://${module.compute.external_ip}:${var.backend_service_port}"

  frontend_runtime_env = merge(
    {
      BACKEND_API_BASE_URL = var.frontend_backend_api_base_url != "" ? var.frontend_backend_api_base_url : local.derived_frontend_backend_api_base_url
      PUBLIC_WS_BASE_URL   = var.frontend_public_ws_base_url != "" ? var.frontend_public_ws_base_url : local.derived_frontend_public_ws_base_url
    },
    var.frontend_env,
  )

  labels = merge(
    {
      app         = var.app_name
      environment = var.environment
      managed_by  = "opentofu"
    },
    var.labels,
  )

  required_services = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "run.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

module "network" {
  source = "../../modules/network"

  project_id                          = var.project_id
  region                              = var.region
  name_prefix                         = local.resource_prefix
  subnet_cidr                         = var.subnet_cidr
  private_service_range_prefix_length = var.cloud_sql_private_range_prefix_length
  ssh_source_ranges                   = var.allowed_ssh_cidrs
  app_source_ranges                   = var.allowed_app_cidrs
  app_ports                           = [tostring(var.backend_service_port)]
  target_tags                         = local.network_tags
  labels                              = local.labels

  depends_on = [google_project_service.required]
}

module "storage" {
  source = "../../modules/storage"

  project_id                       = var.project_id
  region                           = var.region
  bucket_name_prefix               = var.bucket_name_prefix
  sample_bucket_lifecycle_age_days = var.sample_bucket_lifecycle_age_days
  output_bucket_lifecycle_age_days = var.output_bucket_lifecycle_age_days
  labels                           = local.labels

  depends_on = [google_project_service.required]
}

module "frontend" {
  source = "../../modules/frontend-cloud-run"

  project_id              = var.project_id
  region                  = var.region
  repository_id           = var.frontend_artifact_repository_id
  frontend_enabled        = var.frontend_enabled
  frontend_public         = var.frontend_public
  frontend_image          = var.frontend_image
  frontend_service_name   = var.frontend_service_name
  frontend_container_port = var.frontend_container_port
  frontend_env            = local.frontend_runtime_env
  labels                  = local.labels

  depends_on = [google_project_service.required]
}

module "database" {
  source = "../../modules/database"

  project_id                = var.project_id
  region                    = var.region
  name_prefix               = local.resource_prefix
  private_network_self_link = module.network.network_self_link
  database_version          = var.db_version
  tier                      = var.db_tier
  database_name             = var.db_name
  username                  = var.db_user_name
  password                  = var.db_user_password
  disk_size_gb              = var.db_disk_size_gb
  availability_type         = var.db_availability_type
  deletion_protection       = var.db_deletion_protection
  labels                    = local.labels

  depends_on = [module.network]
}

module "compute" {
  source = "../../modules/compute"

  project_id              = var.project_id
  region                  = var.region
  zone                    = var.zone
  name_prefix             = local.resource_prefix
  machine_type            = var.backend_machine_type
  boot_disk_size_gb       = var.backend_boot_disk_size_gb
  boot_image              = var.backend_boot_image
  network_self_link       = module.network.network_self_link
  subnetwork_self_link    = module.network.subnetwork_self_link
  service_account_name    = "${local.resource_prefix}-backend"
  instance_tags           = local.network_tags
  labels                  = local.labels
  backend_container_image = var.backend_container_image
  backend_container_port  = var.backend_container_port
  backend_service_port    = var.backend_service_port
  environment_variables = merge(
    {
      APP_ENV           = var.environment
      DB_HOST           = module.database.private_ip_address
      DB_NAME           = module.database.database_name
      DB_PASSWORD       = var.db_user_password
      DB_PORT           = tostring(module.database.port)
      DB_USER           = module.database.username
      GCP_PROJECT_ID    = var.project_id
      GCP_REGION        = var.region
      GCS_OUTPUT_BUCKET = module.storage.outputs_bucket_name
      GCS_SAMPLE_BUCKET = module.storage.samples_bucket_name
    },
    var.backend_env,
    var.backend_secret_env,
  )

  depends_on = [module.database, module.storage]
}

resource "google_project_iam_member" "backend_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${module.compute.service_account_email}"
}

resource "google_project_iam_member" "backend_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${module.compute.service_account_email}"
}

resource "google_project_iam_member" "backend_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${module.compute.service_account_email}"
}

resource "google_storage_bucket_iam_member" "samples_object_admin" {
  bucket = module.storage.samples_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.compute.service_account_email}"
}

resource "google_storage_bucket_iam_member" "outputs_object_admin" {
  bucket = module.storage.outputs_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.compute.service_account_email}"
}
