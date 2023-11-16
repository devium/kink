variable "cert_manager_config" {
  type = map(string)
}

variable "domain" {
  type = string
}

variable "hetzner_config" {
  type = map(string)
}

variable "kubeconf_file" {
  type = string
}

variable "namespaces" {
  type = map(string)
}

variable "release_name" {
  type = string
}

variable "volume_config" {
  type = map(object({
    handle = string
    size   = string
  }))
}
