terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

resource "hcloud_server" "master" {
  name = "${var.identifier}-master"
  image = var.image
  server_type = var.server_type
  ssh_keys = [
    var.identifier
  ]
  location = var.location
}
