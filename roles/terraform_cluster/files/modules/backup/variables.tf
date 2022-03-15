variable "backup_schedule" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_passwords" {
  type      = map(string)
  sensitive = true
}

variable "namespaces" {
  type = map(string)
}

variable "pvcs" {
  type = map(string)
}

variable "release_name" {
  type = string
}

variable "resources" {
  type = map(map(string))
}

variable "versions" {
  type = map(string)
}
