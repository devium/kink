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

variable "postgres_volume_handle" {
  type = string
}
