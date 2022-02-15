variable "release_name" {
  type = string
}

variable "versions" {
  type = map
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map
}

variable "db_passwords" {
  type = map
  sensitive = true
}

variable "keycloak_admin_password" {
  type = string
  sensitive = true
}
