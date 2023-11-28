locals {
  oidc_url = "https://${var.cluster_vars.domains.keycloak}/realms/${var.cluster_vars.keycloak_realm}/protocol/openid-connect"
}

resource "wikijs_auth_strategies" "auth" {
  strategies = [
    {
      key          = "local"
      display_name = "Local"
      strategy_key = "local"
      enabled      = true
      config       = {}
    },
    {
      key                = "keycloak"
      display_name       = var.config.keycloak.name
      strategy_key       = "oidc"
      enabled            = true
      self_registration  = true
      auto_enroll_groups = []
      domain_whitelist   = []

      config = {
        clientId         = var.config.keycloak.client
        clientSecret     = var.config.keycloak.secret
        authorizationURL = "${local.oidc_url}/auth"
        tokenURL         = "${local.oidc_url}/token"
        userInfoURL      = "${local.oidc_url}/userinfo"
        # Can't store boolean types with this provider so use empty string as false.
        skipUserProfile  = ""
        issuer           = "https://${var.cluster_vars.domains.keycloak}/realms/${var.cluster_vars.keycloak_realm}"
        emailClaim       = "email"
        displayNameClaim = "preferred_username"
        mapGroups        = "1"
        groupsClaim      = "groups"
        # Will have to wait for Wiki.js to include id_token_hint in generic OIDC provider or
        # add group mapping to the Keycloak provider for a proper logout.
        # Group mapping in Keycloak: https://github.com/requarks/wiki/issues/1874
        logoutURL = "${local.oidc_url}/logout?client_id=wiki&post_logout_redirect_uri=https%3A%2F%2F${var.cluster_vars.domains.wiki}%2Flogin"
      }
    }
  ]
}
