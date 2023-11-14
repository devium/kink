terraform {
  cloud {
  }
}

provider "kubernetes" {
  config_path = var.kubeconf_file
}

provider "kubectl" {
  config_path = var.kubeconf_file
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconf_file
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

locals {
  default_csp = {
    "default-src"     = "'none'"
    "script-src"      = "'self'"
    "connect-src"     = "'self' https://${var.app_config.keycloak.subdomain}.${var.domain} wss:"
    "style-src"       = "'self' 'unsafe-inline'"
    "img-src"         = "* blob: data:"
    "font-src"        = "* blob: data:"
    "frame-src"       = "'none'"
    "object-src"      = "'none'"
    "media-src"       = "'self'"
    "manifest-src"    = "'self'"
    "frame-ancestors" = "'none'"
    "base-uri"        = "'self'"
  }
}
