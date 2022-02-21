variable "versions" {
  type = map(any)
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(any)
}

variable "homer_assets_image" {
  type = string
}

variable "project_name" {
  type = string
}

variable "keycloak_realm" {
  type = string
}
