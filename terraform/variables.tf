variable "project_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "suffix" {
  type = string
  default = "dev"
}

variable "db_password" {
  type = string
  sensitive = true
}
