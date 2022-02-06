terraform {
  backend "local" {
  }
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    assert = {
      source  = "bwoznicki/assert"
      version = "0.0.1"
    }
  }
}

# Sanity check to ensure the correct variable set for the workspace is selected.
data "assert_test" "workspace" {
  test = terraform.workspace == var.environment_suffix
  throw = "Selected workspace doesn't fit variable set."
}

# Identifier prefix for any resources allocated.
locals {
  prefix = "${var.project_name}"
}

provider "hcloud" {
  token = var.hcloud_token
}


module "network" {
  source = "./network"
  prefix = local.prefix
  ip_range = var.ip_range
  zone = var.zone
  location = var.location
}

module "master" {
  source = "./node"
  prefix = local.prefix
  name = "master"
  image = var.image
  server_type = var.master_server_type
  ssh_keys = var.ssh_keys
  location = var.location
  network_id = module.network.network_id
  depends_on = [
    module.network
  ]
}

module "worker" {
  count = var.num_workers
  source = "./node"
  prefix = local.prefix
  name = "worker${count.index}"
  image = var.image
  server_type = var.workers_server_type
  ssh_keys = var.ssh_keys
  location = var.location
  network_id = module.network.network_id
  depends_on = [
    module.network
  ]
}

resource "hcloud_floating_ip_assignment" "master_ipv4" {
  floating_ip_id = module.network.floating_ipv4_id
  server_id = module.master.id
}

resource "hcloud_floating_ip_assignment" "master_ipv6" {
  floating_ip_id = module.network.floating_ipv6_id
  server_id = module.master.id
}

module "domain" {
  source = "./domain"
  root_subdomain = var.root_subdomain
  floating_ipv4 = module.network.floating_ipv4
  hdns_token = var.hdns_token
  hdns_zone_id = var.hdns_zone_id
}
