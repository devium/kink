variable vpc_id {
}

variable db_subnet_group_name {
}

variable "db_username" {
  default = "postgres"
}

variable "db_password" {
  type = string
  sensitive = true
}
