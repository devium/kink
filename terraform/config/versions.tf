terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 3.8.1"
    }

    wikijs = {
      source = "startnext/wikijs"
    }
  }
}
