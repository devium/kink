variable "cert_issuer" {
  type = string
}

variable "domain" {
  type = string
}

variable "homer_assets_image" {
  type = string
}

variable "keycloak_realm" {
  type = string
}

variable "namespaces" {
  type = map(string)
}

variable "project_name" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "versions" {
  type = map(string)
}
