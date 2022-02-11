variable "kubeconf_file" {
  type = string
}

variable "hcloud_token" {
  type = string
  sensitive = true
}

variable "floating_ipv4" {
  type = string
}

variable "domain" {
  type = string
}

variable "jitsi_subdomain" {
  type = string
}

variable "use_production_cert" {
  type = bool
}

variable "cert_email" {
  type = string
}

variable "release_name" {
  default = "primary"
}

variable "versions" {
  type = map
}

variable "db_root_password" {
  type = string
  sensitive = true
}

variable "postgres_volume_handle" {
  type = string
}
