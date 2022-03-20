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
