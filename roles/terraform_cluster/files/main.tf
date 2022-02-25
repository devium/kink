terraform {
  backend "local" {
  }

  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
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
  source       = "./hetzner"
  hcloud_token = var.hcloud_token
  versions     = var.versions
}

module "cert_manager" {
  source              = "./cert_manager"
  use_production_cert = var.use_production_cert
  cert_email          = var.cert_email
  release_name        = var.release_name
  domain              = var.domain
  versions            = var.versions
}

module "jitsi" {
  source           = "./jitsi"
  domain           = var.domain
  subdomains       = var.subdomains
  release_name     = var.release_name
  versions         = var.versions
  jitsi_jwt_secret = var.jitsi_jwt_secret
  keycloak_realm   = var.keycloak_realm
}

module "postgres" {
  source                 = "./postgres"
  release_name           = var.release_name
  versions               = var.versions
  db_passwords           = var.db_passwords
  postgres_volume_handle = var.postgres_volume_handle
}

module "keycloak" {
  # Note on module folder name:
  # https://github.com/hashicorp/terraform-provider-helm/issues/735
  source                  = "./keycloak_"
  release_name            = var.release_name
  versions                = var.versions
  domain                  = var.domain
  subdomains              = var.subdomains
  db_passwords            = var.db_passwords
  admin_passwords = var.admin_passwords

  depends_on = [
    module.postgres
  ]
}

module "homer" {
  source             = "./homer"
  domain             = var.domain
  subdomains         = var.subdomains
  versions           = var.versions
  homer_assets_image = var.homer_assets_image
  project_name       = var.project_name
  keycloak_realm     = var.keycloak_realm
}

module "hedgedoc" {
  source           = "./hedgedoc_"
  release_name     = var.release_name
  versions         = var.versions
  domain           = var.domain
  subdomains       = var.subdomains
  db_passwords     = var.db_passwords
  hedgedoc_secret  = var.hedgedoc_secret
  keycloak_realm   = var.keycloak_realm
  keycloak_secrets = var.keycloak_secrets
}

module "nextcloud" {
  source                   = "./nextcloud_"
  release_name             = var.release_name
  versions                 = var.versions
  domain                   = var.domain
  subdomains               = var.subdomains
  db_passwords             = var.db_passwords
  nextcloud_volume_handle  = var.nextcloud_volume_handle
  admin_passwords = var.admin_passwords
}

module "collabora" {
  source                   = "./collabora_"
  release_name             = var.release_name
  versions                 = var.versions
  domain                   = var.domain
  subdomains               = var.subdomains
  admin_passwords = var.admin_passwords
}
