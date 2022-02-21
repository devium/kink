variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(any)
}

variable "keycloak_admin_password" {
  type      = string
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_secrets" {
  type = map(any)
}

variable "google_identity_provider_client_id" {
  type = string
}

variable "google_identity_provider_client_secret" {
  type      = string
  sensitive = true
}
