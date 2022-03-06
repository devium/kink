variable "admin_passwords" {
  type      = map(string)
  sensitive = true
}

variable "backup_schedule" {
  type = string
}

variable "cert_email" {
  type = string
}

variable "db_passwords" {
  type      = map(string)
  sensitive = true
}

variable "domain" {
  type = string
}

variable "floating_ipv4" {
  type = string
}

variable "google_identity_provider_client_id" {
  type = string
}

variable "google_identity_provider_client_secret" {
  type      = string
  sensitive = true
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "hedgedoc_secret" {
  type      = string
  sensitive = true
}

variable "homer_assets_image" {
  type = string
}

variable "jitsi_secrets" {
  type      = map(string)
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_secrets" {
  type      = map(string)
  sensitive = true
}

variable "namespaces" {
  type = map(string)
}

variable "kubeconf_file" {
  type = string
}

variable "project_name" {
  type = string
}

variable "release_name" {
  type = string
}

variable "subdomains" {
  type = map(string)
}

variable "use_production_cert" {
  type = bool
}

variable "versions" {
  type = map(string)
}

variable "volume_handles" {
  type = map(string)
}
