variable "minecraft_admins" {
  type = string
}

variable "minecraft_world" {
  type = string
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

variable "versions" {
  type = map(string)
}
