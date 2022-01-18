locals {
  project_name = "itsademergency-nginx"
  region       = "us-east4"
  zones        = ["us-east4-a", "us-east4-b", "us-east4-c"]
}


variable "tailscalekey" {
  description = "tailscale key for easy access"
  type = string
  sensitive = true
}