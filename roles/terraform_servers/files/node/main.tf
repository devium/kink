terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

resource "hcloud_server" "node" {
  name        = var.name
  image       = var.image
  server_type = var.server_type
  ssh_keys    = var.ssh_keys
  location    = var.location

  network {
    network_id = var.network_id
  }

  lifecycle {
    ignore_changes = [
      network
    ]
  }
}
