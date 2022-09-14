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

  firewall_ids = [
    var.firewall_id
  ]

  lifecycle {
    ignore_changes = [
      network
    ]
  }
}

resource "hcloud_rdns" "rdns_ipv4" {
  server_id  = hcloud_server.node.id
  ip_address = hcloud_server.node.ipv4_address
  dns_ptr    = "${var.name}.${var.domain}"
}

resource "hcloud_rdns" "rdns_ipv6" {
  server_id  = hcloud_server.node.id
  ip_address = hcloud_server.node.ipv6_address
  dns_ptr    = "${var.name}.${var.domain}"
}
