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

  default_default_client_scopes = [
    "email",
    "profile",
    "role_list",
    "roles",
    "web-origins",
    "groups"
  ]
}

resource "keycloak_openid_client" "jitsi" {
  realm_id = keycloak_realm.realm.id
  client_id = "jitsi"

  access_type = "PUBLIC"
  # client_secret = var.keycloak_secrets.jitsi

  standard_flow_enabled = true
  root_url = "https://${var.subdomains.jitsi_keycloak}.${var.subdomains.jitsi}.${var.domain}"
  web_origins = ["+"]
  valid_redirect_uris = ["/*"]
  admin_url = "/"
}

resource "keycloak_openid_client" "nextcloud" {
  realm_id = keycloak_realm.realm.id
  client_id = "nextcloud"

  access_type = "CONFIDENTIAL"
  client_secret = var.keycloak_secrets.nextcloud

  standard_flow_enabled = true
  root_url = "https://${var.subdomains.nextcloud}.${var.domain}"
  web_origins = ["+"]
  valid_redirect_uris = ["/*"]
  admin_url = "/"
}


# Allow users to delete their own account
data "keycloak_openid_client" "account" {
  realm_id = keycloak_realm.realm.id
  client_id = "account"
}
data "keycloak_role" "delete_account" {
  realm_id = keycloak_realm.realm.id
  client_id = data.keycloak_openid_client.account.id
  name = "delete-account"
}

resource "keycloak_role" "client_default_roles" {
  realm_id = keycloak_realm.realm.id
  name = "client_default_roles"
  composite_roles = [
    data.keycloak_role.delete_account.id
  ]
}
resource "keycloak_default_roles" "default_roles" {
  realm_id = keycloak_realm.realm.id
  default_roles = [
    "offline_access",
    "uma_authorization",
    "client_default_roles"
  ]

  depends_on = [
    keycloak_role.client_default_roles
  ]
}
resource "keycloak_required_action" "delete_account" {
  realm_id = keycloak_realm.realm.id
  alias = "delete_account"
  name = "Delete Account"
  priority = 60
  enabled = true
}


# Add groups to profile client scope
resource "keycloak_openid_client_scope" "groups_scope" {
  realm_id = keycloak_realm.realm.id
  name = "groups"
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups_mapper" {
  realm_id = keycloak_realm.realm.id
  name = "groups"
  claim_name = "groups"
  client_scope_id = keycloak_openid_client_scope.groups_scope.id
  full_path = false
}

resource "keycloak_openid_client_default_scopes" "nextcloud_default_scopes" {
  realm_id = keycloak_realm.realm.id
  client_id = keycloak_openid_client.nextcloud.id

  default_scopes = [
    "profile",
    "email",
    "roles",
    "web-origins",
    keycloak_openid_client_scope.groups_scope.name,
  ]
}

resource "keycloak_group" "admin" {
  realm_id = keycloak_realm.realm.id
  name = "admin"
}
