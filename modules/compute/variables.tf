variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "zone" {
  description = "Zone where the backend VM is created."
  type        = string
}

variable "region" {
  description = "Region where the backend VM is created."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for compute resource names."
  type        = string
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
}

variable "boot_image" {
  description = "Source image for the boot disk."
  type        = string
}

variable "network_self_link" {
  description = "Self-link of the VPC network attached to the instance."
  type        = string
}

variable "subnetwork_self_link" {
  description = "Self-link of the subnetwork attached to the instance."
  type        = string
}

variable "service_account_name" {
  description = "Account ID used when creating the backend VM service account."
  type        = string
}

variable "instance_tags" {
  description = "Network tags applied to the backend instance."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels applied to supported resources."
  type        = map(string)
  default     = {}
}

variable "backend_container_image" {
  description = "Optional container image to run on the VM via systemd-managed Docker."
  type        = string
  default     = ""
}

variable "backend_container_port" {
  description = "Port exposed by the backend container."
  type        = number
}

variable "backend_service_port" {
  description = "Host port exposed by the VM and mapped into the backend container."
  type        = number
}

variable "environment_variables" {
  description = "Environment variables written to the backend container env file."
  type        = map(string)
  default     = {}
  sensitive   = true
}
