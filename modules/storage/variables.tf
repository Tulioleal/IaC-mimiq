variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the PVC data buckets."
  type        = string
}

variable "bucket_name_prefix" {
  description = "Globally unique prefix used to derive bucket names."
  type        = string
}

variable "sample_bucket_lifecycle_age_days" {
  description = "Age in days after which voice samples are deleted."
  type        = number
}

variable "output_bucket_lifecycle_age_days" {
  description = "Age in days after which generated outputs are deleted."
  type        = number
}

variable "labels" {
  description = "Labels applied to supported resources."
  type        = map(string)
  default     = {}
}
