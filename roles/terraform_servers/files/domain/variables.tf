variable "dkim_file" {
  type = string
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "floating_ipv4" {
  type = string
}

variable "floating_ipv6" {
  type = string
}

variable "hdns_token" {
  type      = string
  sensitive = true
}

variable "hdns_zone_id" {
  type = string
}

variable "nodes" {
  type = list(object({
    name         = string
    ipv4_address = string
    ipv6_address = string
  }))
}
