resource "keycloak_realm" "realm" {
  realm = var.config.realm

  user_managed_access      = true
  registration_allowed     = true
  edit_username_allowed    = true
  reset_password_allowed   = true
  remember_me              = true
  verify_email             = true
  login_with_email_allowed = true
  duplicate_emails_allowed = false

  internationalization {
    supported_locales = ["ca", "cs", "da", "de", "en", "es", "fr", "hu", "it", "ja", "lt", "nl", "no", "pl", "pt-BR", "ru", "sk", "sv", "tr", "zh-CN"]
    default_locale    = "en"
  }

  smtp_server {
    host              = var.cluster_vars.mail_server
    from              = "${var.config.mail.account}@${var.cluster_vars.domains.domain}"
    port              = 587
    starttls          = true
    from_display_name = var.config.mail.display_name

    auth {
      username = "${var.config.mail.account}@${var.cluster_vars.domains.domain}"
      password = var.config.mail.password
    }
  }

  attributes = {
    userProfileEnabled = true
  }
}

# Add default groups
resource "keycloak_group" "admin" {
  realm_id = keycloak_realm.realm.id
  name     = "admin"
}

resource "keycloak_group" "grafana_editor" {
  realm_id = keycloak_realm.realm.id
  name     = "grafana_editor"
}

# Remove first and last name from user profile
resource "keycloak_realm_user_profile" "userprofile" {
  realm_id = keycloak_realm.realm.id

  attribute {
    name         = "username"
    display_name = "$${username}"

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        min = 3
        max = 31
      }
    }

    validator {
      name = "username-prohibited-characters"
    }

    validator {
      name = "up-username-not-idn-homograph"
    }
  }

  attribute {
    name         = "email"
    display_name = "$${email}"

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        max = 127
      }
    }
  }
}
