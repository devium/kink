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
