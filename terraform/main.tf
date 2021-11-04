terraform {
  backend "remote" {
    organization = "devium"
    workspaces {
      prefix = "autsch-"
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    assert = {
      source  = "bwoznicki/assert"
      version = "0.0.1"
    }
  }
}

data "assert_test" "workspace" {
  test = terraform.workspace == var.suffix
  throw = "Selected workspace doesn't fit variable set."
}

locals {
  identifier = "${var.project_name}-${var.suffix}"
}

provider "aws" {
  shared_credentials_file = "$HOME/.aws/credentials"
  profile = "default"
  region = "eu-central-1"
}

module "vpc" {
  source = "./vpc"
  vpc_name = local.identifier
  cidr_vpc = "192.168.0.0/16"
  cidr_public = "192.168.1.0/24"
  cidr_private = "192.168.2.0/24"
  cidr_private_backup = "192.168.3.0/24"
  identifier = local.identifier
}

resource "aws_route53_zone" "primary" {
  name = var.domain
}

module "db" {
  source = "./db"
  depends_on = [module.vpc]
  vpc_id = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name
  db_password = var.db_password
  db_name = "${var.project_name}${var.suffix}"
  identifier = local.identifier
}

module "s3" {
  source = "./s3"
  bucket_name = "devium-${local.identifier}"
  identifier = local.identifier
}

module "bastion" {
  source = "./bastion"
  depends_on = [module.vpc]
  key_name = local.identifier
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
  domain = var.domain
  identifier = local.identifier
}

module "auth" {
  source = "./auth"
  depends_on = [module.vpc]
  key_name = local.identifier
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
  domain = var.domain
  identifier = local.identifier
}

module "collab" {
  source = "./collab"
  depends_on = [module.vpc]
  key_name = local.identifier
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
  domain = var.domain
  identifier = local.identifier
}

module "matrix" {
  source = "./matrix"
  depends_on = [module.vpc]
  key_name = local.identifier
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
  domain = var.domain
  identifier = local.identifier
}

module "www" {
  source = "./www"
  depends_on = [module.vpc, module.matrix]
  key_name = local.identifier
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
  domain = var.domain
  identifier = local.identifier
}

module "draw" {
  source = "./draw"
  depends_on = [module.vpc]
  key_name = local.identifier
  vpc_id = module.vpc.vpc_id
  cidr_vpc = module.vpc.cidr_vpc
  subnet_public_id = module.vpc.subnet_public_id
  zone_id = aws_route53_zone.primary.zone_id
  domain = var.domain
  identifier = local.identifier
}
