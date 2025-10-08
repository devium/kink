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
  name            = "Username as preferred_username"
  claim_name      = "preferred_username"
  user_property   = "username"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
resource "keycloak_openid_user_attribute_protocol_mapper" "locale" {
  realm_id        = keycloak_realm.realm.id
  name            = "User locale"
  claim_name      = "locale"
  user_attribute  = "locale"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
# https://github.com/hedgedoc/hedgedoc/issues/56
resource "keycloak_openid_user_property_protocol_mapper" "id" {
  realm_id        = keycloak_realm.realm.id
  name            = "User ID"
  claim_name      = "id"
  user_property   = "id"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}
# Pretix-OIDC requires a "name" claim
resource "keycloak_openid_user_property_protocol_mapper" "name" {
  realm_id        = keycloak_realm.realm.id
  name            = "Username as name"
  claim_name      = "name"
  user_property   = "username"
  client_scope_id = keycloak_openid_client_scope.private_profile.id
}


# Add new profile to client default scopes
locals {
  client_ids = concat(
    [
      data.keycloak_openid_client.account.id,
      data.keycloak_openid_client.account_console.id
    ],
    [
      for key, value in local.clients : value.id
    ]
  )
}
resource "keycloak_openid_client_default_scopes" "defaults" {
  count     = length(local.client_ids)
  realm_id  = keycloak_realm.realm.id
  client_id = local.client_ids[count.index]

  default_scopes = [
    keycloak_openid_client_scope.private_profile.name,
    "email",
    "roles"
  ]
}

resource "keycloak_openid_client_optional_scopes" "optionals" {
  count     = length(local.client_ids)
  realm_id  = keycloak_realm.realm.id
  client_id = local.client_ids[count.index]

  # Allow this because some apps request this unchangeably.
  # Ideally, the profile would either be replaced by private_profile
  # or emptied entirely but this is not easily possible with Terraform.
  # (Would need to be imported after realm creation).
  optional_scopes = [
    "profile"
  ]

  depends_on = [
    keycloak_openid_client_default_scopes.defaults
  ]
}
