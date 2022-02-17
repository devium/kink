terraform {
  backend "local" {
  }

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username = "admin"
  password = var.keycloak_admin_password
  url = "https://${var.subdomains.keycloak}.${var.domain}"
  tls_insecure_skip_verify = true
}

module "keycloak" {
  source = "./keycloak"
  keycloak_realm = var.keycloak_realm
}
