variable "ami" {
  # "Amazon Linux 2 AMI"
  default = "ami-089b5384aac360007"
}

variable "bastion_instance_type" {
  default = "t2.nano"
}

variable "collab_instance_type" {
  default = "t2.nano"
}

variable "auth_instance_type" {
  default = "t2.nano"
}

variable "key_name" {
  default = "kink"
}

variable "vpc_id" {
}

variable "cidr_vpc" {
}

variable "subnet_public_id" {
}
