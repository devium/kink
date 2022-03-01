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
  type = map(string)
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
  type = map(string)
}

variable "db_passwords" {
  type      = map(string)
  sensitive = true
}

variable "volume_handles" {
  type = map(string)
}

variable "admin_passwords" {
  type      = map(string)
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

variable "hedgedoc_secret" {
  type      = string
  sensitive = true
}

variable "keycloak_secrets" {
  type      = map(string)
  sensitive = true
}

variable "google_identity_provider_client_id" {
  type = string
}

variable "google_identity_provider_client_secret" {
  type      = string
  sensitive = true
}

variable "backup_schedule" {
  type = string
}
