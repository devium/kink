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
  test = terraform.workspace == var.suffix
  throw = "Selected workspace doesn't fit variable set."
}

# Identifier prefix/suffix for any resources allocated.
locals {
  identifier = "${var.project_name}-${var.suffix}"
}

provider "hcloud" {
  token = var.hcloud_token
}


module "master" {
  source = "./master"
  identifier = local.identifier
  image = var.image
  server_type = var.master_server_type
  location = var.location
}
