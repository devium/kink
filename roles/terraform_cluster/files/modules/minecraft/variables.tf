variable "cert_issuer" {
  type = string
}

variable "default_csp" {
  type = map(string)
}

variable "domain" {
  type = string
}

variable "minecraft_admins" {
  type = string
}

variable "minecraft_modpack_url" {
  type = string
}

variable "minecraft_rcon_password" {
  type      = string
  sensitive = true
}

variable "minecraft_rcon_web_password" {
  type      = string
  sensitive = true
}

variable "minecraft_seed" {
  type = string
}

variable "minecraft_world" {
  type = string
}

variable "namespaces" {
  type = map(string)
}

variable "project_name" {
  type = string
}

variable "pvcs" {
  type = map(string)
}

variable "release_name" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "versions" {
  type = map(string)
}
