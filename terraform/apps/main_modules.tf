locals {
  cluster_vars = {
    db_host        = "${var.release_name}-postgresql.${var.app_config.postgres.namespace}.svc.cluster.local"
    default_csp    = var.default_csp
    issuer         = "letsencrypt"
    keycloak_realm = var.app_config.keycloak.realm
    mail_server    = "${var.app_config.mailserver.subdomain}.${var.domain}"
    release_name   = var.release_name

    db_specs = {
      for app_config_key, app_config_entry in var.app_config :
      app_config_key => {
        database : app_config_entry.db.database
        username : app_config_entry.db.username
        password : app_config_entry.db.password
        params : contains(keys(app_config_entry.db), "params") ? app_config_entry.db.params : ""
      }
      if contains(keys(app_config_entry), "db")
    }

    domains = merge(
      {
        for app_config_key, app_config_entry in var.app_config :
        app_config_key => "${app_config_entry.subdomain}.${var.domain}"
        if contains(keys(app_config_entry), "subdomain")
      },
      {
        domain = var.domain
      }
    )
  }
}


module "backup" {
  source = "./modules/backup"

  cluster_vars = local.cluster_vars
  config       = var.app_config.backup

  depends_on = [
    module.postgres
  ]
}

module "buddy" {
  source = "./modules/buddy"

  cluster_vars = local.cluster_vars
  config       = var.app_config.buddy
}

module "collabora" {
  source = "./modules/collabora"

  cluster_vars = local.cluster_vars
  config       = var.app_config.collabora
}

module "element" {
  source = "./modules/element"

  cluster_vars = local.cluster_vars
  config       = var.app_config.element
}

module "grafana" {
  source = "./modules/grafana"

  cluster_vars = local.cluster_vars
  config       = var.app_config.grafana

  depends_on = [
    module.postgres
  ]
}

module "hedgedoc" {
  source = "./modules/hedgedoc"

  cluster_vars = local.cluster_vars
  config       = var.app_config.hedgedoc

  depends_on = [
    module.postgres
  ]
}

module "home" {
  source = "./modules/home"

  cluster_vars = local.cluster_vars
  config       = var.app_config.home

  depends_on = [
    module.grafana
  ]
}

module "jitsi" {
  source = "./modules/jitsi"

  cluster_vars = local.cluster_vars
  config       = var.app_config.jitsi

  depends_on = [
    module.grafana
  ]
}

module "keycloak" {
  source = "./modules/keycloak"

  cluster_vars = local.cluster_vars
  config       = var.app_config.keycloak

  depends_on = [
    module.postgres
  ]
}

module "mailserver" {
  source = "./modules/mailserver"

  cluster_vars    = local.cluster_vars
  config          = var.app_config.mailserver
  decryption_path = var.decryption_path
}

module "mas" {
  source = "./modules/mas"

  cluster_vars = local.cluster_vars
  config       = var.app_config.mas
}

module "minecraft" {
  source = "./modules/minecraft"

  cluster_vars = local.cluster_vars
  config       = var.app_config.minecraft
}

# module "neodatefix" {
#   source = "./modules/neodatefix"

#   cluster_vars = local.cluster_vars
#   config       = var.app_config.neodatefix
# }

module "nextcloud" {
  source = "./modules/nextcloud"

  cluster_vars = local.cluster_vars
  config       = var.app_config.nextcloud

  depends_on = [
    module.postgres
  ]
}

module "postgres" {
  source = "./modules/postgres"

  cluster_vars = local.cluster_vars
  config       = var.app_config.postgres
}

module "pretix" {
  source = "./modules/pretix"

  cluster_vars = local.cluster_vars
  config       = var.app_config.pretix

  depends_on = [
    module.postgres
  ]
}

module "shlink" {
  source = "./modules/shlink"

  cluster_vars = local.cluster_vars
  config       = var.app_config.shlink

  depends_on = [
    module.postgres
  ]
}

module "shlink_web" {
  source = "./modules/shlink_web"

  cluster_vars = local.cluster_vars
  config       = var.app_config.shlink_web
}

module "sliding_sync" {
  source = "./modules/sliding_sync"

  cluster_vars = local.cluster_vars
  config       = var.app_config.sliding_sync

  depends_on = [
    module.postgres
  ]
}

module "synapse" {
  source = "./modules/synapse"

  cluster_vars = local.cluster_vars
  config       = var.app_config.synapse

  depends_on = [
    module.keycloak,
    module.postgres
  ]
}
