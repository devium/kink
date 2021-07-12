variable "db_password" {
  type = string
  sensitive = true
}

variable "domain" {
  default = "kink.devium.net"
}
