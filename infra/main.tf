resource "google_project" "itsademergency-nginx" {
  name       = local.project_name
  project_id = local.project_name
}

resource "google_compute_health_check" "itsademergency-nginx" {
  name                = "itsademergency-nginx-1"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    request_path = "/healthz"
    port         = "8080"
  }
}

data "google_compute_image" "nginx-packer" {
  family  = "itsademergency-nginx"
  project = local.project_name
}

resource "google_compute_instance_template" "itsademergency-nginx-template" {
  name_prefix  = "itsademergency-nginx-tmpl"
  machine_type = "e2-micro"
  region       = local.region

  // boot disk
  disk {
    source_image = data.google_compute_image.nginx-packer.name
  }

  service_account {
    email = "821593249846-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  scheduling {
    automatic_restart   = true
    min_node_cpus       = 0
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  network_interface {
    network = "https://www.googleapis.com/compute/v1/projects/itsademergency-nginx/global/networks/default"
  }


  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags                    = ["http-server", "https-server"]
  metadata_startup_script = "sudo tailscale up --authkey=${var.tailscalekey} --advertise-routes=10.182.0.0/24,169.254.169.254/32 --accept-dns=false"
}

resource "google_compute_region_instance_group_manager" "itsademergency-nginx" {
  name = "itsademergency-nginx-1"

  base_instance_name        = "itsademergency-nginx-1"
  region                    = local.region
  distribution_policy_zones = local.zones

  version {
    instance_template = google_compute_instance_template.itsademergency-nginx-template.id
  }
  target_size = 2

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.itsademergency-nginx.id
    initial_delay_sec = 180
  }

  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
  }
}