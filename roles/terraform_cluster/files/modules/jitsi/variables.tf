variable "cert_issuer" {
  type = string
}

variable "default_csp" {
  type = map(string)
}

variable "domain" {
  type = string
}

variable "jitsi_secrets" {
  type      = map(string)
  sensitive = true
}

variable "keycloak_clients" {
  type = map(string)
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_secrets" {
  type      = map(string)
  sensitive = true
}

variable "namespaces" {
  type = map(string)
}

variable "release_name" {
  type = string
}

variable "resources" {
  type = map(map(string))
}

variable "subdomains" {
  type = map(string)
}

variable "versions" {
  type = map(string)
}
