terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.90.0"
    }
  }
}

provider "google" {
  credentials = file("../creds/itsademergency-nginx-6a902603bebc.json")
  project     = local.project_name
  region      = "us-east4"
}