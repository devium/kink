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
