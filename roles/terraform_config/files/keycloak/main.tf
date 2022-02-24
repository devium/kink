terraform {
  required_providers {
    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}

resource "keycloak_realm" "realm" {
  realm = var.keycloak_realm

  user_managed_access      = true
  registration_allowed     = true
  edit_username_allowed    = true
  reset_password_allowed   = false
  remember_me              = true
  verify_email             = false
  login_with_email_allowed = true
  duplicate_emails_allowed = false

  login_theme   = "custom"
  account_theme = "custom"

  internationalization {
    supported_locales = ["ca", "cs", "da", "de", "en", "es", "fr", "hu", "it", "ja", "lt", "nl", "no", "pl", "pt-BR", "ru", "sk", "sv", "tr", "zh-CN"]
    default_locale    = "en"
  }

  lifecycle {
    ignore_changes = [
      # Set by Ansible task
      browser_flow,
      default_default_client_scopes
    ]
  }
}

# Get default client IDs
data "keycloak_openid_client" "account" {
  realm_id  = keycloak_realm.realm.id
  client_id = "account"
}
data "keycloak_openid_client" "account_console" {
  realm_id  = keycloak_realm.realm.id
  client_id = "account-console"
}

# Create app clients
resource "keycloak_openid_client" "jitsi" {
  realm_id  = keycloak_realm.realm.id
  client_id = "jitsi"

  access_type = "PUBLIC"
  # client_secret = var.keycloak_secrets.jitsi

  standard_flow_enabled = true
  root_url              = "https://${var.subdomains.jitsi_keycloak}.${var.subdomains.jitsi}.${var.domain}"
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

# Allow users to delete their own account
data "keycloak_role" "delete_account" {
  realm_id  = keycloak_realm.realm.id
  client_id = data.keycloak_openid_client.account.id
  name      = "delete-account"
}
resource "keycloak_role" "client_default_roles" {
  realm_id = keycloak_realm.realm.id
  name     = "client_default_roles"
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
  alias    = "delete_account"
  name     = "Delete Account"
  priority = 60
  enabled  = true
}


# Add default groups
resource "keycloak_group" "admin" {
  realm_id = keycloak_realm.realm.id
  name     = "admin"
}


# Google identity provider for SSO
resource "keycloak_oidc_google_identity_provider" "google" {
  realm         = keycloak_realm.realm.id
  client_id     = var.google_identity_provider_client_id
  client_secret = var.google_identity_provider_client_secret
  trust_email   = true
}
# Map Google first and last name to empty string so no hidden personal data is transferred
resource "keycloak_custom_identity_provider_mapper" "firstname" {
  realm                    = keycloak_realm.realm.id
  name                     = "firstname"
  identity_provider_alias  = keycloak_oidc_google_identity_provider.google.alias
  identity_provider_mapper = "hardcoded-attribute-idp-mapper"

  extra_config = {
    syncMode  = "INHERIT"
    attribute = "firstName"
  }
}
resource "keycloak_custom_identity_provider_mapper" "lastname" {
  realm                    = keycloak_realm.realm.id
  name                     = "lastname"
  identity_provider_alias  = keycloak_oidc_google_identity_provider.google.alias
  identity_provider_mapper = "hardcoded-attribute-idp-mapper"

  extra_config = {
    syncMode  = "INHERIT"
    attribute = "lastName"
  }
}
# Use first name as default username
resource "keycloak_custom_identity_provider_mapper" "username" {
  realm                    = keycloak_realm.realm.id
  name                     = "username"
  identity_provider_alias  = keycloak_oidc_google_identity_provider.google.alias
  identity_provider_mapper = "google-user-attribute-mapper"

  extra_config = {
    syncMode      = "INHERIT"
    jsonField     = "given_name"
    userAttribute = "username"
  }
}


# Create a custom profile scope
resource "keycloak_openid_client_scope" "private_profile" {
  realm_id = keycloak_realm.realm.id
  name     = "private_profile"
}
resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  realm_id        = keycloak_realm.realm.id
  name            = "groups"
  claim_name      = "groups"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
  full_path       = false
}
resource "keycloak_openid_user_property_protocol_mapper" "username" {
  realm_id        = keycloak_realm.realm.id
  name            = "username"
  claim_name      = "preferred_username"
  user_property   = "username"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
resource "keycloak_openid_user_property_protocol_mapper" "firstname" {
  realm_id        = keycloak_realm.realm.id
  name            = "firstname"
  claim_name      = "given_name"
  user_property   = "username"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
resource "keycloak_openid_hardcoded_claim_protocol_mapper" "lastname" {
  realm_id        = keycloak_realm.realm.id
  name            = "lastname"
  claim_name      = "family_name"
  claim_value     = " "
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
resource "keycloak_openid_user_attribute_protocol_mapper" "locale" {
  realm_id        = keycloak_realm.realm.id
  name            = "locale"
  claim_name      = "locale"
  user_attribute  = "locale"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
# https://github.com/hedgedoc/hedgedoc/issues/56
resource "keycloak_openid_user_property_protocol_mapper" "locale" {
  realm_id        = keycloak_realm.realm.id
  name            = "id"
  claim_name      = "id"
  user_property   = "id"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}


# Add new profile to client default scopes
locals {
  client_ids = [
    data.keycloak_openid_client.account.id,
    data.keycloak_openid_client.account_console.id,
    keycloak_openid_client.jitsi.id,
    keycloak_openid_client.nextcloud.id,
    keycloak_openid_client.hedgedoc.id
  ]
}
resource "keycloak_openid_client_default_scopes" "defaults" {
  for_each = toset(local.client_ids)
  realm_id = keycloak_realm.realm.id
  client_id = each.key

  default_scopes = [
    keycloak_openid_client_scope.private_profile.name,
    "email",
    "roles",
    "web-origins"
  ]
}


# Setup authentication flow including optional OTP, U2F, and WebAuthn Passwordless
resource "keycloak_required_action" "webauthn_register" {
  realm_id = keycloak_realm.realm.id
  alias    = "webauthn-register"
  name     = "Webauthn Register"
  priority = 1001
  enabled  = true
}
resource "keycloak_required_action" "webauthn_register_passwordless" {
  realm_id = keycloak_realm.realm.id
  alias    = "webauthn-register-passwordless"
  name     = "Webauthn Register Passwordless"
  priority = 1002
  enabled  = true
}
# Top-level flow
resource "keycloak_authentication_flow" "browser_custom" {
  realm_id = keycloak_realm.realm.id
  alias    = "browser-custom"
}
resource "keycloak_authentication_execution" "cookie" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.browser_custom.alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
}
resource "keycloak_authentication_execution" "identity_provider" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.browser_custom.alias
  authenticator     = "identity-provider-redirector"
  requirement       = "ALTERNATIVE"
  depends_on = [
    keycloak_authentication_execution.cookie
  ]
}
# Login subflow
resource "keycloak_authentication_subflow" "login" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.browser_custom.alias
  alias             = "login"
  requirement       = "ALTERNATIVE"
  depends_on = [
    keycloak_authentication_execution.identity_provider
  ]
}
resource "keycloak_authentication_execution" "username" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.login.alias
  authenticator     = "auth-username-form"
  requirement       = "REQUIRED"
}
# Secrets subflow (password or passwordless)
resource "keycloak_authentication_subflow" "secrets" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.login.alias
  alias             = "secrets"
  requirement       = "REQUIRED"
  depends_on = [
    keycloak_authentication_execution.username
  ]
}
resource "keycloak_authentication_execution" "webauthn_passwordless" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.secrets.alias
  authenticator     = "webauthn-authenticator-passwordless"
  requirement       = "ALTERNATIVE"
}
# Regular password subflow
resource "keycloak_authentication_subflow" "password" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.secrets.alias
  alias             = "password"
  requirement       = "ALTERNATIVE"
  depends_on = [
    keycloak_authentication_execution.webauthn_passwordless
  ]
}
resource "keycloak_authentication_execution" "password" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.password.alias
  authenticator     = "auth-password-form"
  requirement       = "REQUIRED"
}
# Subflow for conditional secondary factors
resource "keycloak_authentication_subflow" "second_factor" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.password.alias
  alias             = "second-factor"
  requirement       = "CONDITIONAL"
  depends_on = [
    keycloak_authentication_execution.password
  ]
}
resource "keycloak_authentication_execution" "second_factor_condition" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.second_factor.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
}
resource "keycloak_authentication_execution" "webauthn" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.second_factor.alias
  authenticator     = "webauthn-authenticator"
  requirement       = "ALTERNATIVE"
  depends_on = [
    keycloak_authentication_execution.second_factor_condition
  ]
}
resource "keycloak_authentication_execution" "otp" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.second_factor.alias
  authenticator     = "auth-otp-form"
  requirement       = "ALTERNATIVE"
  depends_on = [
    keycloak_authentication_execution.webauthn
  ]
}
