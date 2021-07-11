terraform {
  backend "remote" {
    organization = "devium"
    workspaces {
      name = "Kink"
    }
  }
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  shared_credentials_file = "$HOME/.aws/credentials"
  profile = "default"
  region = "eu-central-1"
}

module "vpc" {
  source = "./vpc"
  vpc_name = "kink"
  cidr_vpc = "192.168.0.0/16"
  cidr_public = "192.168.1.0/24"
  cidr_private = "192.168.2.0/24"
  cidr_private_backup = "192.168.3.0/24"
}

resource "aws_route53_zone" "primary" {
  name = "kink.devium.net"
}

module "db" {
  source = "./db"
  depends_on = [module.vpc]
  vpc_id = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name
  db_password = var.db_password
}

module "bastion" {
  source = "./bastion"
  depends_on = [module.vpc]
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
}

module "auth" {
  source = "./auth"
  depends_on = [module.vpc]
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
}

module "collab" {
  source = "./collab"
  depends_on = [module.vpc]
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
}
