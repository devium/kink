variable "cert_issuer" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_passwords" {
  type      = map(string)
  sensitive = true
}

variable "domain" {
  type = string
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

variable "pvcs" {
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

variable "synapse_secrets" {
  type      = map(string)
  sensitive = true
}

variable "versions" {
  type = map(string)
}
