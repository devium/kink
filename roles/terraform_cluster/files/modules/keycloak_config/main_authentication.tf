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
