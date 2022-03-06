variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "namespaces" {
  type = map(string)
}

variable "versions" {
  type = map(string)
}
