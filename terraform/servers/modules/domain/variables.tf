variable "dkim_file" {
  type = string
}

variable "domain" {
  type = string
}

variable "nodes" {
  type = list(object({
    name         = string
    ipv4_address = string
    ipv6_address = string
  }))
}

variable "subdomains" {
  type = map(string)
}
