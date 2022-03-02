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
