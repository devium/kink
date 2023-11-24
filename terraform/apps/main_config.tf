terraform {
  backend "s3" {
  }
}

provider "kubernetes" {
  config_path = var.kubeconf_file
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconf_file
  }
}
