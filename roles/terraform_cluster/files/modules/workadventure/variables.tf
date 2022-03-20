variable "cert_issuer" {
  type = string
}

variable "domain" {
  type = string
}

variable "jitsi_secrets" {
  type      = map(string)
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

variable "subdomains" {
  type = map(string)
}

variable "versions" {
  type = map(string)
}

variable "workadventure_maps_image" {
  type = string
}

variable "workadventure_start_map" {
  type = string
}
