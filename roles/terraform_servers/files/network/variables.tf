variable "domain" {
  type = string
}

variable "ip_range" {
  type = string
}

variable "location" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "zone" {
  type = string
}
