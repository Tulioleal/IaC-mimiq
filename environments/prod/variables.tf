variable "project_id" {
  description = "GCP project ID for the PVC production stack."
  type        = string
}

variable "region" {
  description = "Primary GCP region for production resources."
  type        = string
}

variable "zone" {
  description = "Primary GCP zone for the backend VM."
  type        = string
}

variable "environment" {
  description = "Environment name used in resource naming and labels."
  type        = string
  default     = "prod"
}

variable "app_name" {
  description = "Application name used as the base prefix for resource names."
  type        = string
  default     = "pvc"
}

variable "labels" {
  description = "Additional labels applied to all supported resources."
  type        = map(string)
  default     = {}
}

variable "subnet_cidr" {
  description = "CIDR range for the backend subnet."
  type        = string
  default     = "10.10.0.0/24"
}

variable "cloud_sql_private_range_prefix_length" {
  description = "Prefix length for the private service networking allocation used by Cloud SQL."
  type        = number
  default     = 16
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the backend VM."
  type        = list(string)
}

variable "allowed_app_cidrs" {
  description = "CIDR blocks allowed to reach the backend application port. Leave empty to disable public app ingress."
  type        = list(string)
  default     = []
}

variable "backend_machine_type" {
  description = "Compute Engine machine type for the FastAPI backend VM."
  type        = string
  default     = "e2-standard-2"
}

variable "backend_boot_disk_size_gb" {
  description = "Boot disk size for the backend VM in GB."
  type        = number
  default     = 50
}

variable "backend_boot_image" {
  description = "Source image used for the backend VM boot disk."
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

variable "backend_service_port" {
  description = "Host port exposed by the backend VM firewall and Docker container mapping."
  type        = number
  default     = 8000

  validation {
    condition     = var.backend_service_port >= 1 && var.backend_service_port <= 65535
    error_message = "backend_service_port must be between 1 and 65535."
  }
}

variable "backend_container_port" {
  description = "Container port exposed by the backend application image."
  type        = number
  default     = 8000

  validation {
    condition     = var.backend_container_port >= 1 && var.backend_container_port <= 65535
    error_message = "backend_container_port must be between 1 and 65535."
  }
}

variable "backend_container_image" {
  description = "Optional container image for the FastAPI backend. Leave empty to install Docker without starting the app container."
  type        = string
  default     = ""
}

variable "backend_env" {
  description = "Non-sensitive environment variables injected into the backend container."
  type        = map(string)
  default     = {}
}

variable "backend_secret_env" {
  description = "Sensitive environment variables injected into the backend container."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "frontend_artifact_repository_id" {
  description = "Artifact Registry Docker repository ID for frontend images."
  type        = string
  default     = "pvc"
}

variable "frontend_enabled" {
  description = "Whether to create the Cloud Run frontend service."
  type        = bool
  default     = false
}

variable "frontend_public" {
  description = "Whether the frontend Cloud Run service allows unauthenticated public access."
  type        = bool
  default     = false
}

variable "frontend_image" {
  description = "Container image used by the frontend Cloud Run service."
  type        = string
  default     = ""
}

variable "frontend_service_name" {
  description = "Cloud Run service name for the frontend."
  type        = string
  default     = "pvc-prod-frontend"
}

variable "frontend_container_port" {
  description = "Port exposed by the frontend container."
  type        = number
  default     = 3000

  validation {
    condition     = var.frontend_container_port >= 1 && var.frontend_container_port <= 65535
    error_message = "frontend_container_port must be between 1 and 65535."
  }
}

variable "frontend_env" {
  description = "Environment variables injected into the frontend container."
  type        = map(string)
  default     = {}
}

variable "frontend_backend_api_base_url" {
  description = "Optional backend API base URL injected into frontend Cloud Run. If empty, derive from the backend VM external IP."
  type        = string
  default     = ""
}

variable "frontend_public_ws_base_url" {
  description = "Optional public WebSocket base URL injected into frontend Cloud Run. If empty, derive from the backend VM external IP."
  type        = string
  default     = ""
}

variable "bucket_name_prefix" {
  description = "Globally unique prefix used to derive the samples and outputs bucket names."
  type        = string
}

variable "sample_bucket_lifecycle_age_days" {
  description = "Age in days after which stored voice samples are deleted automatically."
  type        = number
  default     = 30
}

variable "output_bucket_lifecycle_age_days" {
  description = "Age in days after which generated outputs are deleted automatically."
  type        = number
  default     = 90
}

variable "db_version" {
  description = "Cloud SQL PostgreSQL engine version."
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-custom-2-4096"
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "pvc"
}

variable "db_user_name" {
  description = "Application database username."
  type        = string
  default     = "pvc_app"
}

variable "db_user_password" {
  description = "Application database user password."
  type        = string
  sensitive   = true
}

variable "db_disk_size_gb" {
  description = "Initial disk size for Cloud SQL in GB."
  type        = number
  default     = 20
}

variable "db_availability_type" {
  description = "Cloud SQL availability type."
  type        = string
  default     = "ZONAL"
}

variable "db_deletion_protection" {
  description = "Whether deletion protection is enabled for Cloud SQL."
  type        = bool
  default     = true
}
