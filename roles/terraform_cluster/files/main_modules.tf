module "namespaces" {
  source = "./modules/namespaces"

  namespaces = var.namespaces
}

module "rke2" {
  source = "./modules/rke2"
}

module "hetzner" {
  source = "./modules/hetzner"

  hcloud_token = var.hcloud_token
  namespaces   = module.namespaces.namespaces
  versions     = var.versions

  depends_on = [
    module.rke2
  ]
}

module "volumes" {
  source = "./modules/volumes"

  csi_driver     = module.hetzner.csi_driver
  namespaces     = module.namespaces.namespaces
  volume_handles = var.volume_handles
}

module "cert_manager" {
  source = "./modules/cert_manager"

  cert_email          = var.cert_email
  domain              = var.domain
  namespaces          = module.namespaces.namespaces
  release_name        = var.release_name
  use_production_cert = var.use_production_cert
  versions            = var.versions
}

module "postgres" {
  source = "./modules/postgres"

  db_passwords = var.db_passwords
  namespaces   = module.namespaces.namespaces
  release_name = var.release_name
  pvcs         = module.volumes.pvcs
  versions     = var.versions
}

module "keycloak" {
  # Note on module folder name:
  # https://github.com/hashicorp/terraform-provider-helm/issues/735
  source = "./modules/keycloak"

  admin_passwords = var.admin_passwords
  db_host         = module.postgres.host
  db_passwords    = var.db_passwords
  domain          = var.domain
  cert_issuer     = module.cert_manager.issuer
  namespaces      = module.namespaces.namespaces
  release_name    = var.release_name
  subdomains      = var.subdomains
  versions        = var.versions
}

module "keycloak_config" {
  source = "./modules/keycloak_config"

  domain           = var.domain
  keycloak_realm   = var.keycloak_realm
  keycloak_secrets = var.keycloak_secrets
  subdomains       = var.subdomains

  google_identity_provider_client_id     = var.google_identity_provider_client_id
  google_identity_provider_client_secret = var.google_identity_provider_client_secret

  depends_on = [
    module.keycloak
  ]
}

module "jitsi" {
  source = "./modules/jitsi"

  domain           = var.domain
  cert_issuer      = module.cert_manager.issuer
  jitsi_secrets    = var.jitsi_secrets
  keycloak_clients = module.keycloak_config.clients
  keycloak_realm   = var.keycloak_realm
  keycloak_secrets = var.keycloak_secrets
  namespaces       = module.namespaces.namespaces
  release_name     = var.release_name
  subdomains       = var.subdomains
  versions         = var.versions

  depends_on = [
    module.rke2
  ]
}

module "home" {
  source = "./modules/home"

  domain          = var.domain
  home_site_image = var.home_site_image
  cert_issuer     = module.cert_manager.issuer
  namespaces      = module.namespaces.namespaces
  release_name    = var.release_name
  subdomains      = var.subdomains
  versions        = var.versions
}

module "hedgedoc" {
  source = "./modules/hedgedoc"

  db_host          = module.postgres.host
  db_passwords     = var.db_passwords
  domain           = var.domain
  hedgedoc_secret  = var.hedgedoc_secret
  cert_issuer      = module.cert_manager.issuer
  keycloak_clients = module.keycloak_config.clients
  keycloak_realm   = var.keycloak_realm
  keycloak_secrets = var.keycloak_secrets
  namespaces       = module.namespaces.namespaces
  release_name     = var.release_name
  subdomains       = var.subdomains
  versions         = var.versions
}

module "nextcloud" {
  source = "./modules/nextcloud"

  admin_passwords = var.admin_passwords
  db_host         = module.postgres.host
  db_passwords    = var.db_passwords
  domain          = var.domain
  cert_issuer     = module.cert_manager.issuer
  namespaces      = module.namespaces.namespaces
  release_name    = var.release_name
  pvcs            = module.volumes.pvcs
  subdomains      = var.subdomains
  versions        = var.versions
}

module "collabora" {
  source = "./modules/collabora"

  admin_passwords = var.admin_passwords
  domain          = var.domain
  cert_issuer     = module.cert_manager.issuer
  namespaces      = module.namespaces.namespaces
  release_name    = var.release_name
  subdomains      = var.subdomains
  versions        = var.versions
}

module "synapse" {
  source = "./modules/synapse"

  db_host          = module.postgres.host
  db_passwords     = var.db_passwords
  domain           = var.domain
  cert_issuer      = module.cert_manager.issuer
  keycloak_clients = module.keycloak_config.clients
  keycloak_realm   = var.keycloak_realm
  keycloak_secrets = var.keycloak_secrets
  namespaces       = module.namespaces.namespaces
  pvcs             = module.volumes.pvcs
  release_name     = var.release_name
  subdomains       = var.subdomains
  synapse_secrets  = var.synapse_secrets
  versions         = var.versions
}

module "element" {
  source = "./modules/element"

  domain       = var.domain
  cert_issuer  = module.cert_manager.issuer
  namespaces   = module.namespaces.namespaces
  release_name = var.release_name
  subdomains   = var.subdomains
  versions     = var.versions
}

module "backup" {
  source = "./modules/backup"

  backup_schedule = var.backup_schedule
  db_host         = module.postgres.host
  db_passwords    = var.db_passwords
  namespaces      = module.namespaces.namespaces
  pvcs            = module.volumes.pvcs
  release_name    = var.release_name
  versions        = var.versions
}

module "grafana" {
  source = "./modules/grafana"

  admin_passwords  = var.admin_passwords
  domain           = var.domain
  cert_issuer      = module.cert_manager.issuer
  db_host          = module.postgres.host
  db_passwords     = var.db_passwords
  keycloak_clients = module.keycloak_config.clients
  keycloak_realm   = var.keycloak_realm
  keycloak_secrets = var.keycloak_secrets
  namespaces       = module.namespaces.namespaces
  release_name     = var.release_name
  subdomains       = var.subdomains
  versions         = var.versions
}

module "grafana_config" {
  source = "./modules/grafana_config"

  versions = var.versions

  depends_on = [
    module.grafana
  ]
}
