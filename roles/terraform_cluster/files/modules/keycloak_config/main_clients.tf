resource "keycloak_openid_client" "jitsi" {
  realm_id  = keycloak_realm.realm.id
  client_id = "jitsi"

  access_type = "PUBLIC"
  # client_secret = var.keycloak_secrets.jitsi

  standard_flow_enabled = true
  root_url              = "https://${var.subdomains.jitsi_keycloak}.${var.domain}"
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

  standard_flow_enabled = true
  root_url              = "https://${var.subdomains.synapse}.${var.domain}"
  web_origins           = ["+"]
  valid_redirect_uris   = ["/*"]
  admin_url             = "/"
}
