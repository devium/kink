variable "domain" {
  type = string
}

variable "cert_email" {
  type = string
}

variable "hdns_token" {
  type      = string
  sensitive = true
}

variable "hdns_zone_id" {
  type      = string
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

variable "use_production_cert" {
  type = bool
}

variable "versions" {
  type = map(string)
}
