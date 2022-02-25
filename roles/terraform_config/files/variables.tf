variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "admin_passwords" {
  type      = map(string)
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_secrets" {
  type = map(string)
}

variable "google_identity_provider_client_id" {
  type = string
}

variable "google_identity_provider_client_secret" {
  type      = string
  sensitive = true
}
