variable "app_config" {
  type = any
}

variable "decryption_path" {
  type = string
}

variable "default_csp" {
  type = map(string)
}

variable "domain" {
  type = string
}

variable "kubeconf_file" {
  type = string
}

variable "release_name" {
  type = string
}
