variable "versions" {
  type = map
}

variable "release_name" {
  type = string
}

variable "db_passwords" {
  type = map
  sensitive = true
}

variable "postgres_volume_handle" {
  type = string
}
