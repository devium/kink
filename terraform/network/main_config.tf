terraform {
  backend "s3" {
  }
}

provider "kubernetes" {
  config_path = var.kubeconf_file
}
