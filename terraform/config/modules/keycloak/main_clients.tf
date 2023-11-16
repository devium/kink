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

  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.nextcloud.secret

  standard_flow_enabled = true
  root_url              = "https://${var.cluster_vars.domains.nextcloud}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["/*"]
  admin_url             = "/"
}

resource "keycloak_openid_client" "hedgedoc" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.hedgedoc.client

  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.hedgedoc.secret

  standard_flow_enabled = true
  root_url              = "https://${var.cluster_vars.domains.hedgedoc}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["/*"]
  admin_url             = "/"
}

resource "keycloak_openid_client" "synapse" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.synapse.client

  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.synapse.secret

  standard_flow_enabled               = true
  root_url                            = "https://${var.cluster_vars.domains.synapse}"
  backchannel_logout_url              = "https://${var.cluster_vars.domains.synapse}/_synapse/client/oidc/backchannel_logout"
  backchannel_logout_session_required = true
  web_origins                         = ["+"]
  valid_redirect_uris                 = ["/*"]
  admin_url                           = "/"
}

resource "keycloak_openid_client" "grafana" {
  realm_id  = keycloak_realm.realm.id
  client_id = var.clients.grafana.client

  access_type   = "CONFIDENTIAL"
  client_secret = var.clients.grafana.secret

  standard_flow_enabled = true
  root_url              = "https://${var.cluster_vars.domains.grafana}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["/*"]
  admin_url             = "/"
}

locals {
  clients = {
    jitsi     = keycloak_openid_client.jitsi,
    nextcloud = keycloak_openid_client.nextcloud,
    hedgedoc  = keycloak_openid_client.hedgedoc,
    synapse   = keycloak_openid_client.synapse,
    grafana   = keycloak_openid_client.grafana
  }
}
