variable "prefix" {
  type = string
}

variable "name" {
  type = string
}

variable "image" {
  type = string
}

variable "server_type" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "location" {
  type = string
}

variable "network_id" {
  type = number
}
