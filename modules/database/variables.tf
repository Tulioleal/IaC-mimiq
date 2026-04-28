variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the Cloud SQL instance."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for database resource names."
  type        = string
}

variable "private_network_self_link" {
  description = "Self-link of the VPC used for private Cloud SQL connectivity."
  type        = string
}

variable "database_version" {
  description = "Cloud SQL database engine version."
  type        = string
}

variable "tier" {
  description = "Cloud SQL machine tier."
  type        = string
}

variable "database_name" {
  description = "Application database name."
  type        = string
}

variable "username" {
  description = "Application database username."
  type        = string
}

variable "password" {
  description = "Application database password."
  type        = string
  sensitive   = true
}

variable "disk_size_gb" {
  description = "Initial disk size for the Cloud SQL instance in GB."
  type        = number
}

variable "availability_type" {
  description = "Cloud SQL availability type."
  type        = string
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled on the Cloud SQL instance."
  type        = bool
}

variable "labels" {
  description = "User labels applied to supported resources."
  type        = map(string)
  default     = {}
}
