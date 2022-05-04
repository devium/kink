terraform {
  backend "local" {
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
  url       = "https://${var.subdomains.keycloak}.${var.domain}"
  client_id = "admin-cli"
  base_path = ""

  username = "admin"
  password = var.admin_passwords.keycloak

  tls_insecure_skip_verify = true
  initial_login            = false
}

provider "grafana" {
  url                  = "https://${var.subdomains.grafana}.${var.domain}"
  auth                 = "admin:${var.admin_passwords.grafana}"
  insecure_skip_verify = true
}

locals {
  default_csp = {
    "default-src"     = "'none'"
    "script-src"      = "'self'"
    "connect-src"     = "'self' https://${var.subdomains.keycloak}.${var.domain}"
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
