variable "admin_passwords" {
  type      = map(string)
  sensitive = true
}

variable "cert_issuer" {
  type = string
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

variable "subdomains" {
  type = map(string)
}

variable "versions" {
  type = map(string)
}
