variable "kubeconf_file" {
  type = string
}

variable "hcloud_token" {
  type = string
  sensitive = true
}

variable "hcloud_csi_version" {
  default = "v1.6.0"
}
