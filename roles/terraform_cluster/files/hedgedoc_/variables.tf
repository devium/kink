variable "release_name" {
  type = string
}

variable "versions" {
  type = map(string)
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "db_passwords" {
  type      = map(string)
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}

variable "hedgedoc_secret" {
  type      = string
  sensitive = true
}

variable "keycloak_secrets" {
  type      = map(string)
  sensitive = true
}
