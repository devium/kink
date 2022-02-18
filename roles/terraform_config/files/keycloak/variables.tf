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
