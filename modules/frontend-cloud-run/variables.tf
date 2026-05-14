variable "project_id" {
  description = "GCP project ID for frontend resources."
  type        = string
}

variable "region" {
  description = "GCP region for Artifact Registry and Cloud Run."
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry Docker repository ID for application images."
  type        = string
}

variable "repository_description" {
  description = "Description for the Artifact Registry repository."
  type        = string
  default     = "Docker images for PVC applications."
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

variable "labels" {
  description = "Labels applied to supported frontend resources."
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the Cloud Run service."
  type        = bool
  default     = true
}
