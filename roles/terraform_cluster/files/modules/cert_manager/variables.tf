variable "domain" {
  type = string
}

variable "cert_email" {
  type = string
}

variable "namespaces" {
  type = map(string)
}

variable "release_name" {
  type = string
}

variable "use_production_cert" {
  type = bool
}

variable "versions" {
  type = map(string)
}
