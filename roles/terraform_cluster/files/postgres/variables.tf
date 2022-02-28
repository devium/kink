variable "versions" {
  type = map(string)
}

variable "release_name" {
  type = string
}

variable "db_passwords" {
  type      = map(string)
  sensitive = true
}

variable "volume_handles" {
  type = map(string)
}
