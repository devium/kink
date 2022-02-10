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

variable "jitsi_version" {
  type = string
}

variable "hcloud_csi_version" {
  default = "v1.6.0"
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
