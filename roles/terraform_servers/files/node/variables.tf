variable "domain" {
  type = string
}

variable "firewall_id" {
  type = number
}

variable "image" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "server_type" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "network_id" {
  type = number
}

variable "subdomains" {
  type = map(string)
}

variable "taints" {
  type = string
}
