variable "release_name" {
  type = string
}

variable "versions" {
  type = map(any)
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(any)
}

variable "db_passwords" {
  type      = map(any)
  sensitive = true
}

variable "keycloak_admin_password" {
  type      = string
  sensitive = true
}
