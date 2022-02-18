terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
    }
  }
}

resource "keycloak_realm" "realm" {
  realm = var.keycloak_realm

  user_managed_access = true
  registration_allowed = true
  edit_username_allowed = true
  reset_password_allowed = false
  remember_me = true
  verify_email = false
  login_with_email_allowed = true
  duplicate_emails_allowed = false

  login_theme = "custom"
  account_theme = "custom"

  internationalization {
    supported_locales = ["ca","cs","da","de","en","es","fr","hu","it","ja","lt","nl","no","pl","pt-BR","ru","sk","sv","tr","zh-CN"]
    default_locale = "en"
  }
}

locals {
  urls = {
    jitsi_keycloak = "https://${var.subdomains.jitsi_keycloak}.${var.subdomains.jitsi}.${var.domain}"
  }
}


resource "keycloak_openid_client" "jitsi" {
  realm_id = keycloak_realm.realm.id
  client_id = "jitsi"

  access_type = "PUBLIC"
  client_secret = var.keycloak_secrets.jitsi

  standard_flow_enabled = true
  root_url = local.urls.jitsi_keycloak
  web_origins = ["+"]
  valid_redirect_uris = ["/*"]
  admin_url = "/"
}
