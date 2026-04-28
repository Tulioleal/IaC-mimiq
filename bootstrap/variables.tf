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
