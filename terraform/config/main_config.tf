terraform {
  backend "s3" {
  }
}

provider "keycloak" {
  url       = "https://${var.app_config.keycloak.subdomain}.${var.domain}"
  client_id = "admin-cli"
  base_path = ""

  username = "admin"
  password = var.app_config.keycloak.admin_password

  tls_insecure_skip_verify = true
  initial_login            = false
}

provider "wikijs" {
  site_url = "https://${var.app_config.wiki.subdomain}.${var.domain}/graphql"
  email    = var.app_config.wiki.admin.email
  password = var.app_config.wiki.admin.password
}
