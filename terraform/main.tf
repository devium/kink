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
  prefix = "${var.project_name}-${var.environment_suffix}"
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
  source = "./master"
  prefix = local.prefix
  image = var.image
  server_type = var.master_server_type
  ssh_keys = var.ssh_keys
  location = var.location
  network_id = module.network.network_id
}

module "worker" {
  count = var.num_workers
  source = "./worker"
  prefix = local.prefix
  name = "worker${count.index}"
  image = var.image
  server_type = var.workers_server_type
  ssh_keys = var.ssh_keys
  location = var.location
  network_id = module.network.network_id
}
