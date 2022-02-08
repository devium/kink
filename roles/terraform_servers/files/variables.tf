variable "hcloud_token" {
  type = string
  sensitive = true
}

variable "hdns_token" {
  type = string
  sensitive = true
}

variable "hdns_zone_id" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "image" {
  default = "ubuntu-20.04"
}

variable "master_server_type" {
  default = "cx21"
}

variable "workers_server_type" {
  default = "cx21"
}

variable "zone" {
  default = "eu-central"
}

variable "location" {
  default = "nbg1"
}

variable "num_workers" {
  default = 2
}

variable "ip_range" {
  default = "10.0.0.0/16"
}

variable "root_subdomain" {
  default = "@"
}

variable "inventory_file" {
  type = string
}
