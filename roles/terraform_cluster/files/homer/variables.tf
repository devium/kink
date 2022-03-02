variable "versions" {
  type = map(string)
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(string)
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
