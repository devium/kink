variable "versions" {
  type = map(any)
}

variable "release_name" {
  type = string
}

variable "db_passwords" {
  type      = map(any)
  sensitive = true
}

variable "postgres_volume_handle" {
  type = string
}
