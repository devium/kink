variable "dkim_file" {
  type = string
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "hdns_token" {
  type      = string
  sensitive = true
}

variable "hdns_zone_id" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "image" {
  default = "ubuntu-22.04"
}

variable "nodes" {
  type = list(map(string))
}

variable "zone" {
  default = "eu-central"
}

variable "location" {
  default = "nbg1"
}

variable "inventory_file" {
  type = string
}
