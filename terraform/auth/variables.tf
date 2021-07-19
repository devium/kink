variable "ami" {
  # "Amazon Linux 2 AMI"
  default = "ami-089b5384aac360007"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
}

variable "vpc_id" {
}

variable "cidr_vpc" {
}

variable "subnet_public_id" {
}

variable "zone_id" {
}

variable "domain" {
}

variable "identifier" {
}
