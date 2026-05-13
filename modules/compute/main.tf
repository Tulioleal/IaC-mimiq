locals {
  explicit_backend_url    = trimsuffix(lookup(var.environment_variables, "BACKEND_URL", ""), "/")
  explicit_backend_ws_url = trimsuffix(lookup(var.environment_variables, "BACKEND_WS_URL", ""), "/")
  backend_public_url      = trimsuffix(lookup(var.environment_variables, "BACKEND_PUBLIC_URL", ""), "/")
  callback_base_url       = local.explicit_backend_url != "" ? local.explicit_backend_url : local.backend_public_url
  backend_url             = local.callback_base_url != "" ? local.callback_base_url : "http://${google_compute_address.backend_ip.address}:${var.backend_service_port}"
  backend_ws_base_url = local.callback_base_url != "" ? (
    startswith(local.callback_base_url, "https://") ? "wss://${trimprefix(local.callback_base_url, "https://")}" : (
      startswith(local.callback_base_url, "http://") ? "ws://${trimprefix(local.callback_base_url, "http://")}" : local.callback_base_url
    )
  ) : "ws://${google_compute_address.backend_ip.address}:${var.backend_service_port}"
  backend_ws_url = local.explicit_backend_ws_url != "" ? local.explicit_backend_ws_url : "${local.backend_ws_base_url}/internal/tts-worker/ws"
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.service_account_name
  display_name = "${var.name_prefix} backend VM"
}

resource "google_compute_address" "backend_ip" {
  name   = "${var.name_prefix}-backend-ip"
  region = var.region
}

resource "google_compute_instance" "this" {
  project      = var.project_id
  zone         = var.zone
  name         = "${var.name_prefix}-backend"
  machine_type = var.machine_type
  tags         = var.instance_tags
  labels       = var.labels

  boot_disk {
    auto_delete = true

    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link

    access_config {
      nat_ip = google_compute_address.backend_ip.address
    }
  }

  metadata_startup_script = templatefile("${path.module}/templates/startup.sh.tftpl", {
    container_image = var.backend_container_image
    container_port  = var.backend_container_port
    environment_json = jsonencode(merge(
      var.environment_variables,
      {
        BACKEND_PUBLIC_IP = google_compute_address.backend_ip.address
        BACKEND_URL       = local.backend_url
        BACKEND_WS_URL    = local.backend_ws_url
      }
    ))
    service_port = var.backend_service_port
    backend_ip   = google_compute_address.backend_ip.address
    backend_port = var.backend_service_port
  })

  service_account {
    email  = google_service_account.this.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  allow_stopping_for_update = true
}
