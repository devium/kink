variable "versions" {
  type = map
}

variable "release_name" {
  type = string
}

variable "db_root_password" {
  type = string
  sensitive = true
}

variable "postgres_volume_handle" {
  type = string
}
