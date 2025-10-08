resource "keycloak_openid_client" "jitsi" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.jitsi.client

  access_type = "PUBLIC"

  standard_flow_enabled = true
  root_url              = "https://${var.cluster_vars.domains.jitsi}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["/*"]
  admin_url             = "/"
}

resource "keycloak_openid_client" "nextcloud" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.nextcloud.client

  name          = "Nextcloud"
  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.nextcloud.secret

  standard_flow_enabled               = true
  root_url                            = "https://${var.cluster_vars.domains.nextcloud}"
  web_origins                         = ["+"]
  valid_redirect_uris                 = ["/*"]
  admin_url                           = "/"
  backchannel_logout_url              = "https://${var.cluster_vars.domains.nextcloud}/apps/user_oidc/backchannel-logout/${var.clients.nextcloud.name}"
  backchannel_logout_session_required = true
}

resource "keycloak_openid_client" "hedgedoc" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.hedgedoc.client

  name          = "HedgeDoc"
  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.hedgedoc.secret

  standard_flow_enabled       = true
  root_url                    = "https://${var.cluster_vars.domains.hedgedoc}"
  web_origins                 = ["+"]
  valid_redirect_uris         = ["/*"]
  admin_url                   = "/"
  frontchannel_logout_enabled = true
  frontchannel_logout_url     = "https://${var.cluster_vars.domains.hedgedoc}/logout"
}

resource "keycloak_openid_client" "mas" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.mas.client

  name          = "Matrix Authentication Service"
  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.mas.secret

  standard_flow_enabled = true
  root_url              = "https://${var.cluster_vars.domains.mas}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["https://${var.cluster_vars.domains.mas}/upstream/callback/*"]
  admin_url             = "/"
}

resource "keycloak_openid_client" "grafana" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.grafana.client

  name          = "Grafana"
  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.grafana.secret

  standard_flow_enabled       = true
  root_url                    = "https://${var.cluster_vars.domains.grafana}"
  web_origins                 = ["+"]
  valid_redirect_uris         = ["/*"]
  admin_url                   = "/"
  frontchannel_logout_enabled = true
  frontchannel_logout_url     = "https://${var.cluster_vars.domains.grafana}/logout"
}

resource "keycloak_openid_client" "wiki" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.wiki.client

  name          = "Wiki.js"
  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.wiki.secret

  standard_flow_enabled       = true
  root_url                    = "https://${var.cluster_vars.domains.wiki}"
  web_origins                 = ["+"]
  valid_redirect_uris         = ["/*"]
  admin_url                   = "/"
  frontchannel_logout_enabled = true
  frontchannel_logout_url     = "https://${var.cluster_vars.domains.wiki}/logout"
}

resource "keycloak_openid_client" "pretix" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.pretix.client

  name          = "Pretix"
  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.pretix.secret

  standard_flow_enabled       = true
  root_url                    = "https://${var.cluster_vars.domains.pretix}"
  web_origins                 = ["+"]
  valid_redirect_uris         = ["/*"]
  admin_url                   = "/"
  frontchannel_logout_enabled = true
  frontchannel_logout_url     = "https://${var.cluster_vars.domains.pretix}/logout"
}

locals {
  clients = {
    jitsi     = keycloak_openid_client.jitsi,
    nextcloud = keycloak_openid_client.nextcloud,
    hedgedoc  = keycloak_openid_client.hedgedoc,
    mas       = keycloak_openid_client.mas,
    grafana   = keycloak_openid_client.grafana,
    wiki      = keycloak_openid_client.wiki,
    pretix    = keycloak_openid_client.pretix
  }
}
