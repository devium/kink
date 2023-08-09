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

variable "hdns_token" {
  type      = string
  sensitive = true
}

variable "hdns_zone_id" {
  type      = string
  sensitive = true
}

variable "hedgedoc_secret" {
  type      = string
  sensitive = true
}

variable "home_site_image" {
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

variable "mail_account" {
  type = string
}

variable "mail_password" {
  type      = string
  sensitive = true
}

variable "mail_secrets_files" {
  type = map(string)
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

variable "kubeconf_file" {
  type = string
}

variable "project_name" {
  type = string
}

variable "release_name" {
  type = string
}

variable "resources" {
  type = map(map(string))
}

variable "subdomains" {
  type = map(string)
}

variable "synapse_secrets" {
  type      = map(string)
  sensitive = true
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

variable "volume_sizes" {
  type = map(string)
}

variable "workadventure_maps_image" {
  type = string
}

variable "workadventure_start_map" {
  type = string
}
