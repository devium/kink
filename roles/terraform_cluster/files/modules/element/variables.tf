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

variable "versions" {
  type = map(string)
}

variable "subdomains" {
  type = map(string)
}
