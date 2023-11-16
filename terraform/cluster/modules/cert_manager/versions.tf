terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }

    helm = {
      source = "hashicorp/helm"
    }
  }
}
