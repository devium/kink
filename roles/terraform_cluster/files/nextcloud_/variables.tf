variable "release_name" {
  type = string
}

variable "versions" {
  type = map(string)
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "db_passwords" {
  type      = map(string)
  sensitive = true
}

variable "nextcloud_volume_handle" {
  type = string
}

variable "nextcloud_admin_password" {
  type      = string
  sensitive = true
}
