terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
    }

    helm = {
      source = "hashicorp/helm"
    }

    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 3.8.1"
    }

    grafana = {
      source = "grafana/grafana"
    }
  }
}
