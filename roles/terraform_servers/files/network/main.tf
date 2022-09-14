terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

resource "hcloud_network" "network" {
  name     = "network"
  ip_range = var.ip_range
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "server"
  network_zone = var.zone
  ip_range     = var.ip_range
}

resource "hcloud_floating_ip" "floating_ipv4" {
  name          = "floating-ipv4"
  type          = "ipv4"
  home_location = var.location
}

resource "hcloud_floating_ip" "floating_ipv6" {
  name          = "floating-ipv6"
  type          = "ipv6"
  home_location = var.location
}

resource "hcloud_rdns" "rdns_ipv4" {
  floating_ip_id = hcloud_floating_ip.floating_ipv4.id
  ip_address     = hcloud_floating_ip.floating_ipv4.ip_address
  dns_ptr        = "${var.subdomains.mailserver}.${var.domain}"
}

resource "hcloud_rdns" "rdns_ipv6" {
  floating_ip_id = hcloud_floating_ip.floating_ipv6.id
  ip_address     = hcloud_floating_ip.floating_ipv6.ip_address
  dns_ptr        = "${var.subdomains.mailserver}.${var.domain}"
}
