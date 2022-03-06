# Get default client IDs
data "keycloak_openid_client" "account" {
  realm_id  = keycloak_realm.realm.id
  client_id = "account"
}
data "keycloak_openid_client" "account_console" {
  realm_id  = keycloak_realm.realm.id
  client_id = "account-console"
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
    keycloak_openid_client.hedgedoc.id,
    keycloak_openid_client.synapse.id
  ]
}
resource "keycloak_openid_client_default_scopes" "defaults" {
  count     = length(local.client_ids)
  realm_id  = keycloak_realm.realm.id
  client_id = local.client_ids[count.index]

  default_scopes = [
    keycloak_openid_client_scope.private_profile.name,
    "email",
    "roles",
    "web-origins"
  ]
}
