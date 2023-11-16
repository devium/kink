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
