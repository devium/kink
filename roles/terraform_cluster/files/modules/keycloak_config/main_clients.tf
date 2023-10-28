resource "keycloak_openid_client" "jitsi" {
  realm_id  = keycloak_realm.realm.id
  client_id = "jitsi"

  access_type = "PUBLIC"
  # client_secret = var.keycloak_secrets.jitsi

  standard_flow_enabled = true
  root_url              = "https://${var.subdomains.jitsi}.${var.domain}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["/*"]
  admin_url             = "/"
}

resource "keycloak_openid_client" "nextcloud" {
  realm_id  = keycloak_realm.realm.id
  client_id = "nextcloud"

  access_type   = "CONFIDENTIAL"
  client_secret = var.keycloak_secrets.nextcloud

  standard_flow_enabled = true
  root_url              = "https://${var.subdomains.nextcloud}.${var.domain}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["/*"]
  admin_url             = "/"
}

resource "keycloak_openid_client" "hedgedoc" {
  realm_id  = keycloak_realm.realm.id
  client_id = "hedgedoc"

  access_type   = "CONFIDENTIAL"
  client_secret = var.keycloak_secrets.hedgedoc

  standard_flow_enabled = true
  root_url              = "https://${var.subdomains.hedgedoc}.${var.domain}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["/*"]
  admin_url             = "/"
}

resource "keycloak_openid_client" "synapse" {
  realm_id  = keycloak_realm.realm.id
  client_id = "synapse"

  access_type   = "CONFIDENTIAL"
  client_secret = var.keycloak_secrets.synapse

  standard_flow_enabled               = true
  root_url                            = "https://${var.subdomains.synapse}.${var.domain}"
  backchannel_logout_url              = "https://${var.subdomains.synapse}.${var.domain}/_synapse/client/oidc/backchannel_logout"
  backchannel_logout_session_required = true
  web_origins                         = ["+"]
  valid_redirect_uris                 = ["/*"]
  admin_url                           = "/"
}

resource "keycloak_openid_client" "grafana" {
  realm_id  = keycloak_realm.realm.id
  client_id = "grafana"

  access_type   = "CONFIDENTIAL"
  client_secret = var.keycloak_secrets.grafana

  standard_flow_enabled = true
  root_url              = "https://${var.subdomains.grafana}.${var.domain}"
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
