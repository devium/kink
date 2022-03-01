variable "release_name" {
  type = string
}

variable "versions" {
  type = map(string)
}

variable "db_passwords" {
  type      = map(string)
  sensitive = true
}

variable "volume_handles" {
  type = map(string)
}

variable "backup_schedule" {
  type = string
}
