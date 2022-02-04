terraform {
  backend "remote" {
    organization = "autsch"
    workspaces {
      prefix = "autsch-"
    }
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

provider "aws" {
  shared_credentials_file = var.aws_credentials
  profile = var.aws_profile
  region = var.aws_region
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
  domain = var.domain
  floating_ipv4 = module.network.floating_ipv4
}
