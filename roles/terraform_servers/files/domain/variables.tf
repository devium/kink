variable "root_subdomain" {
  type = string
}

variable "floating_ipv4" {
  type = string
}

variable "floating_ipv6" {
  type = string
}

variable "hdns_token" {
  type = string
  sensitive = true
}

variable "hdns_zone_id" {
  type = string
}
