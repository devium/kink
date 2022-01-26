variable "project_name" {
  type = string
}

variable "environment_suffix" {
  type = string
}

variable "hcloud_token" {
  type = string
  sensitive = true
}

variable "image" {
  default = "ubuntu-20.04"
}

variable "master_server_type" {
  default = "cx11"
}

variable "workers_server_type" {
  default = "cx21"
}

variable "ssh_keys" {
  default = []
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
