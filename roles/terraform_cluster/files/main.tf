terraform {
  backend "local" {
  }

  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }

    keycloak = {
      source = "mrparkers/keycloak"
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

provider "keycloak" {
  client_id                = "admin-cli"
  username                 = "admin"
  password                 = var.admin_passwords.keycloak
  url                      = "https://${var.subdomains.keycloak}.${var.domain}"
  tls_insecure_skip_verify = true
  initial_login            = false
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

  depends_on = [
    module.cert_manager
  ]
}

module "postgres" {
  source         = "./postgres"
  release_name   = var.release_name
  versions       = var.versions
  db_passwords   = var.db_passwords
  volume_handles = var.volume_handles

  depends_on = [
    module.hetzner
  ]
}

module "keycloak" {
  # Note on module folder name:
  # https://github.com/hashicorp/terraform-provider-helm/issues/735
  source          = "./keycloak_"
  release_name    = var.release_name
  versions        = var.versions
  domain          = var.domain
  subdomains      = var.subdomains
  db_passwords    = var.db_passwords
  admin_passwords = var.admin_passwords

  depends_on = [
    module.postgres,
    module.cert_manager
  ]
}

module "keycloak_config" {
  source = "./keycloak_config"

  keycloak_realm                         = var.keycloak_realm
  keycloak_secrets                       = var.keycloak_secrets
  domain                                 = var.domain
  subdomains                             = var.subdomains
  google_identity_provider_client_id     = var.google_identity_provider_client_id
  google_identity_provider_client_secret = var.google_identity_provider_client_secret

  depends_on = [
    module.keycloak
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

  depends_on = [
    module.cert_manager
  ]
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

  depends_on = [
    module.postgres,
    module.cert_manager
  ]
}

module "nextcloud" {
  source          = "./nextcloud_"
  release_name    = var.release_name
  versions        = var.versions
  domain          = var.domain
  subdomains      = var.subdomains
  db_passwords    = var.db_passwords
  volume_handles  = var.volume_handles
  admin_passwords = var.admin_passwords

  depends_on = [
    module.postgres,
    module.cert_manager
  ]
}

module "collabora" {
  source          = "./collabora_"
  release_name    = var.release_name
  versions        = var.versions
  domain          = var.domain
  subdomains      = var.subdomains
  admin_passwords = var.admin_passwords

  depends_on = [
    module.cert_manager
  ]
}

module "synapse" {
  source           = "./synapse_"
  release_name     = var.release_name
  versions         = var.versions
  domain           = var.domain
  subdomains       = var.subdomains
  db_passwords     = var.db_passwords
  keycloak_realm   = var.keycloak_realm
  keycloak_secrets = var.keycloak_secrets
  volume_handles   = var.volume_handles

  depends_on = [
    module.postgres,
    module.cert_manager,
    module.keycloak_config
  ]
}

module "element" {
  source       = "./element"
  release_name = var.release_name
  versions     = var.versions
  domain       = var.domain
  subdomains   = var.subdomains

  depends_on = [
    module.cert_manager
  ]
}

module "backup" {
  source          = "./backup"
  release_name    = var.release_name
  versions        = var.versions
  db_passwords    = var.db_passwords
  volume_handles  = var.volume_handles
  backup_schedule = var.backup_schedule

  depends_on = [
    module.postgres
  ]
}
