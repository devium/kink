resource "aws_vpc" "main" {
  cidr_block = var.cidr_vpc
  instance_tenancy = var.tenancy
  enable_dns_support = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = var.identifier
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.identifier
  }
}

resource "aws_route" "route_public" {
  route_table_id = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.cidr_public
  availability_zone = "eu-central-1a"

  tags = {
    Name = "${var.identifier}-public"
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.cidr_private
  availability_zone = "eu-central-1b"

  tags = {
    Name = "${var.identifier}-private"
  }
}

resource "aws_subnet" "private_backup" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.cidr_private_backup
  availability_zone = "eu-central-1c"

  tags = {
    Name = "${var.identifier}-private-backup"
  }
}

resource "aws_db_subnet_group" "db_subnet" {
  name = var.identifier
  subnet_ids = ["${aws_subnet.private.id}", "${aws_subnet.private_backup.id}"]
}

resource "aws_eip" "gw" {
  vpc = true
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = var.identifier
  }
}
