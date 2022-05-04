variable "admin_passwords" {
  type      = map(string)
  sensitive = true
}

variable "cert_issuer" {
  type = string
}

variable "default_csp" {
  type = map(string)
}

variable "domain" {
  type = string
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
