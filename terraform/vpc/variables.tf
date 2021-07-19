variable "vpc_name" {
  type = string
}

variable "cidr_vpc" {
  type = string
  default = "10.0.0.0/16"
}

variable "tenancy" {
  type = string
  default = "default"
}

variable enable_dns_support {
  default = true
}

variable enable_dns_hostnames {
  default = true
}

variable "cidr_public" {
}

variable "cidr_private" {
}

variable "cidr_private_backup" {
}

variable "identifier" {
}
