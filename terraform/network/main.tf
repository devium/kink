terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

resource "hcloud_network" "network" {
  name = var.prefix
  ip_range = var.ip_range
}

resource "hcloud_network_subnet" "subnet" {
  network_id = hcloud_network.network.id
  type = "server"
  network_zone = var.zone
  ip_range = var.ip_range
}

resource "hcloud_floating_ip" "floating_ipv4" {
  name = "${var.prefix}-ipv4"
  type = "ipv4"
  home_location = var.location
}

resource "hcloud_floating_ip" "floating_ipv6" {
  name = "${var.prefix}-ipv6"
  type = "ipv6"
  home_location = var.location
}
