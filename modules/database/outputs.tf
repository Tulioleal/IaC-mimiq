output "instance_name" {
  description = "Cloud SQL instance name."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Cloud SQL connection name."
  value       = google_sql_database_instance.this.connection_name
}

output "private_ip_address" {
  description = "Private IP address assigned to the Cloud SQL instance."
  value       = google_sql_database_instance.this.private_ip_address
}

output "database_name" {
  description = "Application database name."
  value       = google_sql_database.app.name
}

output "username" {
  description = "Application database username."
  value       = google_sql_user.app.name
}

output "port" {
  description = "PostgreSQL port exposed by Cloud SQL."
  value       = 5432
}
