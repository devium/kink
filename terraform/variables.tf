variable "project_name" {
  type = string
}

variable "suffix" {
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

variable "location" {
  default = "nbg1"
}
