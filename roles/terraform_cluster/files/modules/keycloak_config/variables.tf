variable "domain" {
  type = string
}

variable "google_identity_provider_client_id" {
  type = string
}

variable "google_identity_provider_client_secret" {
  type      = string
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_secrets" {
  type = map(string)
}

variable "mail_account" {
  type = string
}

variable "mail_password" {
  type      = string
  sensitive = true
}

variable "project_name" {
  type = string
}

variable "subdomains" {
  type = map(string)
}
