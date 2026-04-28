variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the subnetwork."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for network resource names."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the primary subnet."
  type        = string
}

variable "private_service_range_prefix_length" {
  description = "Prefix length for the reserved private service networking range."
  type        = number
}

variable "ssh_source_ranges" {
  description = "CIDR blocks allowed to SSH into the backend VM."
  type        = list(string)
}

variable "app_source_ranges" {
  description = "CIDR blocks allowed to access the backend application port."
  type        = list(string)
}

variable "app_ports" {
  description = "Application ports exposed by the backend firewall rule."
  type        = list(string)
}

variable "target_tags" {
  description = "Network tags applied to backend instances targeted by firewall rules."
  type        = list(string)
}

variable "labels" {
  description = "Labels applied to supported resources."
  type        = map(string)
  default     = {}
}
