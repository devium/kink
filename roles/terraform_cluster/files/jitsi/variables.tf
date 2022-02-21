variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(any)
}

variable "release_name" {
  type = string
}

variable "versions" {
  type = map(any)
}

variable "jitsi_jwt_secret" {
  type      = string
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}
