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

variable "pvcs" {
  type = map(string)
}

variable "release_name" {
  type = string
}

variable "secrets_files" {
  type = map(string)
}

variable "subdomains" {
  type = map(string)
}

variable "versions" {
  type = map(string)
}
