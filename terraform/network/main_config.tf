terraform {
  cloud {
  }
}

provider "kubernetes" {
  config_path = var.kubeconf_file
}
