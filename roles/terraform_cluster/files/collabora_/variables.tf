variable "release_name" {
  type = string
}

variable "versions" {
  type = map(string)
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "admin_passwords" {
  type      = map(string)
  sensitive = true
}
