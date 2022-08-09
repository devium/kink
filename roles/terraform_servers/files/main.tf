terraform {
  backend "local" {
  }
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}


module "network" {
  source   = "./network"
  ip_range = var.ip_range
  zone     = var.zone
  location = var.location
}

module "firewall" {
  source   = "./firewall"
  ip_range = var.ip_range
}

module "master" {
  source      = "./node"
  name        = "master"
  image       = var.image
  server_type = var.master_server_type
  ssh_keys    = var.ssh_keys
  location    = var.location
  network_id  = module.network.network_id
  firewall_id = module.firewall.firewall_id
  depends_on = [
    module.network
  ]
}

module "worker" {
  count       = var.num_workers
  source      = "./node"
  name        = "worker${count.index}"
  image       = var.image
  server_type = var.workers_server_type
  ssh_keys    = var.ssh_keys
  location    = var.location
  network_id  = module.network.network_id
  firewall_id = module.firewall.firewall_id
  depends_on = [
    module.network
  ]
}

resource "hcloud_floating_ip_assignment" "master_ipv4" {
  floating_ip_id = module.network.floating_ipv4_id
  server_id      = module.master.id
}

resource "hcloud_floating_ip_assignment" "master_ipv6" {
  floating_ip_id = module.network.floating_ipv6_id
  server_id      = module.master.id
}

module "domain" {
  source        = "./domain"
  dkim_file     = var.dkim_file
  domain        = var.domain
  subdomains    = var.subdomains
  floating_ipv4 = module.network.floating_ipv4
  floating_ipv6 = module.network.floating_ipv6
  hdns_token    = var.hdns_token
  hdns_zone_id  = var.hdns_zone_id
  nodes         = concat([module.master], module.worker)
}
