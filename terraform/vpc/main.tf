resource "aws_vpc" "main" {
  cidr_block = var.cidr_vpc
  instance_tenancy = var.tenancy
  enable_dns_support = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-Gateway"
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
    Name = "${var.vpc_name}-net-public"
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.cidr_private
  availability_zone = "eu-central-1b"

  tags = {
    Name = "${var.vpc_name}-net-private"
  }
}

resource "aws_subnet" "private_backup" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.cidr_private_backup
  availability_zone = "eu-central-1c"

  tags = {
    Name = "${var.vpc_name}-net-private-backup"
  }
}

resource "aws_db_subnet_group" "db_subnet" {
  name = "${var.vpc_name}-db-subnet-group"
  subnet_ids = ["${aws_subnet.private.id}", "${aws_subnet.private_backup.id}"]
}

resource "aws_eip" "gw" {
  vpc = true
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.vpc_name}-EIP"
  }
}

resource "aws_nat_gateway" "gw" {
  subnet_id = aws_subnet.public.id
  allocation_id = aws_eip.gw.id

  tags = {
    Name = "${var.vpc_name}-NAT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "${var.vpc_name}-rt-private"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_vpc.main.main_route_table_id
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_backup" {
  subnet_id = aws_subnet.private_backup.id
  route_table_id = aws_route_table.private.id
}
