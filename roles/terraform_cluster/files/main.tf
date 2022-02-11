terraform {
  backend "local" {
  }

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

provider "kubectl" {
  config_path = var.kubeconf_file
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconf_file
  }
}


module "hetzner" {
  source = "./hetzner"
  hcloud_token = var.hcloud_token
  versions = var.versions
}

module "cert_manager" {
  source = "./cert_manager"
  use_production_cert = var.use_production_cert
  cert_email = var.cert_email
  release_name = var.release_name
  domain = var.domain
  versions = var.versions
}

module "jitsi" {
  source = "./jitsi"
  floating_ipv4 = var.floating_ipv4
  domain = var.domain
  jitsi_subdomain = var.jitsi_subdomain
  release_name = var.release_name
  versions = var.versions
}
