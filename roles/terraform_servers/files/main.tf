terraform {
  cloud {
  }
}

provider "hcloud" {
  token = var.hcloud_token
}


module "firewall" {
  source = "./firewall"
}

module "node" {
  count = length(var.nodes)

  domain      = var.domain
  firewall_id = module.firewall.firewall_id
  image       = var.nodes[count.index].image
  location    = var.location
  name        = var.nodes[count.index].name
  server_type = var.nodes[count.index].type
  source      = "./node"
  ssh_keys    = var.ssh_keys
  subdomains  = var.subdomains
  taints      = var.nodes[count.index].taints
}

module "domain" {
  dkim_file    = var.dkim_file
  domain       = var.domain
  hdns_token   = var.hdns_token
  hdns_zone_id = var.hdns_zone_id
  nodes        = module.node
  source       = "./domain"
  subdomains   = var.subdomains
}
