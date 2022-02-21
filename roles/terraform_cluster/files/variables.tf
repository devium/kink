variable "kubeconf_file" {
  type = string
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "floating_ipv4" {
  type = string
}

variable "domain" {
  type = string
}

variable "subdomains" {
  type = map(any)
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
  type = map(any)
}

variable "db_passwords" {
  type      = map(any)
  sensitive = true
}

variable "postgres_volume_handle" {
  type = string
}

variable "keycloak_admin_password" {
  type      = string
  sensitive = true
}

variable "jitsi_jwt_secret" {
  type      = string
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}

variable "homer_assets_image" {
  type = string
}

variable "project_name" {
  type = string
}
