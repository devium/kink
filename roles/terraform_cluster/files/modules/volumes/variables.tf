variable "csi_driver" {
  type = string
}

variable "namespaces" {
  type = map(string)
}

variable "volume_handles" {
  type = map(string)
}

variable "volume_sizes" {
  type = map(string)
}
