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

# Get default client IDs
data "keycloak_openid_client" "account" {
  realm_id = keycloak_realm.realm.id
  client_id = "account"
}
data "keycloak_openid_client" "account_console" {
  realm_id = keycloak_realm.realm.id
  client_id = "account-console"
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


resource "keycloak_group" "admin" {
  realm_id = keycloak_realm.realm.id
  name = "admin"
}


# Google identity provider for SSO
resource "keycloak_oidc_google_identity_provider" "google" {
  realm = keycloak_realm.realm.id
  client_id = var.google_identity_provider_client_id
  client_secret = var.google_identity_provider_client_secret
  trust_email = true
}
# Map first and last name to empty string so no hidden personal data is transferred
resource "keycloak_custom_identity_provider_mapper" "firstname" {
  realm = keycloak_realm.realm.id
  name = "firstname"
  identity_provider_alias = keycloak_oidc_google_identity_provider.google.alias
  identity_provider_mapper = "hardcoded-attribute-idp-mapper"

  extra_config = {
    syncMode = "INHERIT"
    attribute = "firstName"
  }
}
resource "keycloak_custom_identity_provider_mapper" "lastname" {
  realm = keycloak_realm.realm.id
  name = "lastname"
  identity_provider_alias = keycloak_oidc_google_identity_provider.google.alias
  identity_provider_mapper = "hardcoded-attribute-idp-mapper"

  extra_config = {
    syncMode = "INHERIT"
    attribute = "lastName"
  }
}
# Use first name as default username
resource "keycloak_custom_identity_provider_mapper" "username" {
  realm = keycloak_realm.realm.id
  name = "username"
  identity_provider_alias = keycloak_oidc_google_identity_provider.google.alias
  identity_provider_mapper = "google-user-attribute-mapper"

  extra_config = {
    syncMode = "INHERIT"
    jsonField = "given_name"
    userAttribute = "username"
  }
}


# Create a custom profile scope
resource "keycloak_openid_client_scope" "private_profile" {
  realm_id = keycloak_realm.realm.id
  name = "private_profile"
}
resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  realm_id = keycloak_realm.realm.id
  name = "groups"
  claim_name = "groups"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
  full_path = false
}
resource "keycloak_openid_user_property_protocol_mapper" "username" {
  realm_id = keycloak_realm.realm.id
  name = "username"
  claim_name = "preferred_username"
  user_property = "username"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
resource "keycloak_openid_user_property_protocol_mapper" "firstname" {
  realm_id = keycloak_realm.realm.id
  name = "firstname"
  claim_name = "given_name"
  user_property = "username"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
resource "keycloak_openid_hardcoded_claim_protocol_mapper" "lastname" {
  realm_id = keycloak_realm.realm.id
  name = "lastname"
  claim_name = "family_name"
  claim_value = " "
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
resource "keycloak_openid_user_attribute_protocol_mapper" "locale" {
  realm_id = keycloak_realm.realm.id
  name = "locale"
  claim_name = "locale"
  user_attribute = "locale"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}

# Replace profile from all non-admin client default scopes
# TODO: The Terraform module might one day support realm-wide default scopes or "default default scopes"
resource "keycloak_openid_client_default_scopes" "default_scopes" {
  for_each = toset([
    data.keycloak_openid_client.account.id,
    data.keycloak_openid_client.account_console.id,
    keycloak_openid_client.jitsi.id,
    keycloak_openid_client.nextcloud.id
  ])

  realm_id = keycloak_realm.realm.id
  client_id = each.value

  default_scopes = [
    "email",
    "roles",
    "web-origins",
    keycloak_openid_client_scope.private_profile.name,
  ]
}
