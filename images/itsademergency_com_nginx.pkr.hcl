packer {
  required_plugins {
    googlecompute = {
      version = " >= 0.0.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "itsademergency-nginx" {
  project_id          = "itsademergency-nginx"
  source_image_family = "ubuntu-minimal-2110"
  ssh_username        = "packer"
  zone                = "us-east4-c"
  image_family        = "itsademergency-nginx"
}

build {
  sources = ["sources.googlecompute.itsademergency-nginx"]
  provisioner "shell" {
    inline = ["/usr/bin/cloud-init status --wait"]
  }
  provisioner "shell" {
    inline = ["curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -"]
  }
  provisioner "shell" {
    inline = ["curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list"]
  }
  provisioner "shell" {
    inline = ["sudo apt-get update"]
  }
  provisioner "shell" {
    inline = ["sudo apt-get -y upgrade"]
  }
  provisioner "shell" {
    inline = ["sudo apt-get -y install apt-utils"]
  }
  provisioner "shell" {
    inline = ["sudo apt-get -y install nginx tailscale"]
  }
  provisioner "shell" {
    inline = ["sudo rm /etc/nginx/sites-enabled/default"]
  }
  provisioner "file" {
    source      = "files"
    destination = "/tmp"
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/files/itsademergency.conf /etc/nginx/sites-available/itsademergency.conf"]
  }
  provisioner "shell" {
    inline = ["sudo ln -s /etc/nginx/sites-available/itsademergency.conf /etc/nginx/sites-enabled"]
  }
  provisioner "shell" {
    inline = ["sudo mkdir -p /etc/goss && sudo cp /tmp/files/goss.yaml /etc/goss"]
  }
  provisioner "shell" {
    inline = ["sudo systemctl reload nginx.service"]
  }
  provisioner "shell" {
    inline = ["sudo curl -L https://github.com/aelsabbahy/goss/releases/latest/download/goss-linux-amd64 -o /usr/local/bin/goss && sudo chmod +rx /usr/local/bin/goss"]
  }
  provisioner "shell" {
    inline = ["cd /etc/goss && sudo /usr/local/bin/goss v"]
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/files/goss.service /etc/systemd/system && sudo systemctl enable goss.service"]
  }
}