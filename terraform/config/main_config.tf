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

provider "grafana" {
  url                  = "https://${var.app_config.grafana.subdomain}.${var.domain}"
  auth                 = "admin:${var.app_config.grafana.admin_password}"
  insecure_skip_verify = true
}
