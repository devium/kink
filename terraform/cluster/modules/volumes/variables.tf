variable "namespaces" {
  type = map(string)
}

variable "volume_config" {
  type = map(object({
    handle = string
    size   = string
  }))
}
