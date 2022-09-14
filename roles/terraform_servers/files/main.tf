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
  domain     = var.domain
  ip_range   = var.ip_range
  location   = var.location
  source     = "./network"
  subdomains = var.subdomains
  zone       = var.zone
}

module "firewall" {
  ip_range = var.ip_range
  source   = "./firewall"
}

module "master" {
  domain      = var.domain
  firewall_id = module.firewall.firewall_id
  image       = var.image
  location    = var.location
  name        = "master"
  network_id  = module.network.network_id
  server_type = var.master_server_type
  source      = "./node"
  ssh_keys    = var.ssh_keys
  subdomains  = var.subdomains

  depends_on = [
    module.network
  ]
}

module "worker" {
  count       = var.num_workers
  domain      = var.domain
  firewall_id = module.firewall.firewall_id
  image       = var.image
  location    = var.location
  name        = "worker${count.index}"
  network_id  = module.network.network_id
  server_type = var.workers_server_type
  source      = "./node"
  ssh_keys    = var.ssh_keys
  subdomains  = var.subdomains

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
  dkim_file     = var.dkim_file
  domain        = var.domain
  floating_ipv4 = module.network.floating_ipv4
  floating_ipv6 = module.network.floating_ipv6
  hdns_token    = var.hdns_token
  hdns_zone_id  = var.hdns_zone_id
  nodes         = concat([module.master], module.worker)
  source        = "./domain"
  subdomains    = var.subdomains
}
