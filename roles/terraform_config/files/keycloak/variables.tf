variable "domain" {
  type = string
}

variable "subdomains" {
  type = map
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_secrets" {
  type = map
}

variable "google_identity_provider_client_id" {
  type = string
}

variable "google_identity_provider_client_secret" {
  type = string
  sensitive = true
}
