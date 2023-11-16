locals {
  cluster_vars = {
    mail_server = "${var.app_config.mailserver.subdomain}.${var.domain}"

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

module "keycloak" {
  source = "./modules/keycloak"

  clients = {
    for app_config_key, app_config_entry in var.app_config :
    app_config_key => app_config_entry.keycloak
    if contains(keys(app_config_entry), "keycloak")
  }
  cluster_vars = local.cluster_vars
  config       = var.app_config.keycloak
}
