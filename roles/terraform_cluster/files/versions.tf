terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    helm = {
      source = "hashicorp/helm"
    }

    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}
