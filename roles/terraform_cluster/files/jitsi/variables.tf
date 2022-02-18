variable "domain" {
  type = string
}

variable "subdomains" {
  type = map
}

variable "release_name" {
  type = string
}

variable "versions" {
  type = map
}

variable "jitsi_jwt_secret" {
  type = string
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}
