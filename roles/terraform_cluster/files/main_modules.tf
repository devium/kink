locals {
  cluster_vars = {
    db_host        = "${var.release_name}-postgresql.${var.app_config.postgres.namespace}.svc.cluster.local"
    default_csp    = local.default_csp
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

module "namespaces" {
  source = "./modules/namespaces"

  namespaces = [
    for app_config_key, app_config_entry in var.app_config :
    app_config_entry.namespace
    if contains(keys(app_config_entry), "namespace")
  ]
}

module "rke2" {
  source = "./modules/rke2"

  default_csp        = local.default_csp
  mailserver_service = "${var.app_config.mailserver.namespace}/${var.release_name}-docker-mailserver"

  depends_on = [
    module.namespaces
  ]
}

module "hetzner" {
  source = "./modules/hetzner"

  config       = var.app_config.hetzner
  release_name = var.release_name

  depends_on = [
    module.rke2
  ]
}

module "volumes" {
  source = "./modules/volumes"

  volume_config = {
    for app_config_key, app_config_entry in var.app_config :
    app_config_key => {
      handle : app_config_entry.volume.handle
      namespace : app_config_entry.namespace
      size : app_config_entry.volume.size
    }
    if contains(keys(app_config_entry), "volume")
  }

  depends_on = [
    module.hetzner
  ]
}


module "backup" {
  source = "./modules/backup"

  cluster_vars = local.cluster_vars
  config       = var.app_config.backup

  depends_on = [
    module.namespaces
  ]
}

module "buddy" {
  source = "./modules/buddy"

  cluster_vars = local.cluster_vars
  config       = var.app_config.buddy

  depends_on = [
    module.namespaces
  ]
}

module "cert_manager" {
  source = "./modules/cert_manager"

  cluster_vars = local.cluster_vars
  config       = var.app_config.cert_manager

  depends_on = [
    module.namespaces
  ]
}

module "collabora" {
  source = "./modules/collabora"

  cluster_vars = local.cluster_vars
  config       = var.app_config.collabora

  depends_on = [
    module.namespaces
  ]
}

module "element" {
  source = "./modules/element"

  cluster_vars = local.cluster_vars
  config       = var.app_config.element

  depends_on = [
    module.namespaces
  ]
}

module "grafana" {
  source = "./modules/grafana"

  cluster_vars = local.cluster_vars
  config       = var.app_config.grafana

  depends_on = [
    module.namespaces
  ]
}

module "hedgedoc" {
  source = "./modules/hedgedoc"

  cluster_vars = local.cluster_vars
  config       = var.app_config.hedgedoc

  depends_on = [
    module.namespaces
  ]
}

module "home" {
  source = "./modules/home"

  cluster_vars = local.cluster_vars
  config       = var.app_config.home

  depends_on = [
    module.namespaces
  ]
}

module "jitsi" {
  source = "./modules/jitsi"

  cluster_vars = local.cluster_vars
  config       = var.app_config.jitsi

  depends_on = [
    module.namespaces
  ]
}

module "keycloak" {
  source = "./modules/keycloak"

  cluster_vars = local.cluster_vars
  config       = var.app_config.keycloak

  depends_on = [
    module.namespaces
  ]
}

module "mailserver" {
  source = "./modules/mailserver"

  cluster_vars = local.cluster_vars
  config       = var.app_config.mailserver

  depends_on = [
    module.namespaces
  ]
}

module "minecraft" {
  source = "./modules/minecraft"

  cluster_vars = local.cluster_vars
  config       = var.app_config.minecraft

  depends_on = [
    module.namespaces
  ]
}

module "nextcloud" {
  source = "./modules/nextcloud"

  cluster_vars = local.cluster_vars
  config       = var.app_config.nextcloud

  depends_on = [
    module.namespaces
  ]
}

module "postgres" {
  source = "./modules/postgres"

  cluster_vars = local.cluster_vars
  config       = var.app_config.postgres

  depends_on = [
    module.namespaces
  ]
}

module "pretix" {
  source = "./modules/pretix"

  cluster_vars = local.cluster_vars
  config       = var.app_config.pretix

  depends_on = [
    module.namespaces
  ]
}

module "shlink" {
  source = "./modules/shlink"

  cluster_vars = local.cluster_vars
  config       = var.app_config.shlink

  depends_on = [
    module.namespaces
  ]
}

module "shlink_web" {
  source = "./modules/shlink_web"

  cluster_vars = local.cluster_vars
  config       = var.app_config.shlink_web

  depends_on = [
    module.namespaces
  ]
}

module "sliding_sync" {
  source = "./modules/sliding_sync"

  cluster_vars = local.cluster_vars
  config       = var.app_config.sliding_sync

  depends_on = [
    module.namespaces
  ]
}

module "synapse" {
  source = "./modules/synapse"

  cluster_vars = local.cluster_vars
  config       = var.app_config.synapse

  depends_on = [
    module.namespaces
  ]
}


module "keycloak_config" {
  source = "./modules/keycloak_config"

  clients = {
    for app_config_key, app_config_entry in var.app_config :
    app_config_key => {
      client_id : app_config_entry.keycloak.client
      secret : contains(keys(app_config_entry.keycloak), "secret") ? app_config_entry.keycloak.secret : ""
      url : "https://${app_config_entry.subdomain}.${var.domain}"
    }
    if contains(keys(app_config_entry), "keycloak")
  }
  cluster_vars = local.cluster_vars
  config       = var.app_config.keycloak

  depends_on = [
    module.keycloak
  ]
}

module "grafana_config" {
  source = "./modules/grafana_config"

  versions = {
    jitsi_prometheus_exporter = var.app_config.jitsi.version_prometheus_exporter
    nginx_prometheus_exporter = var.app_config.home.version_nginx_prometheus_exporter
  }

  depends_on = [
    module.grafana
  ]
}
