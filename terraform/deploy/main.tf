resource "aws_route53_zone" "primary" {
  name = "kink.devium.net"
}

resource "aws_instance" "collab" {
  ami = var.ami
  instance_type = var.collab_instance_type
  subnet_id = var.subnet_public_id
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.collab-sg.id ]
  associate_public_ip_address = true

  tags = {
    Name = "Collab"
  }
}

resource "aws_security_group" "collab-sg" {
  name = "collab-security-group"
  vpc_id = var.vpc_id

  # Ping
  ingress {
    protocol = "icmp"
    from_port = 8
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = [var.cidr_vpc]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "collab" {
  zone_id = aws_route53_zone.primary.zone_id
  name = "collab.kink.devium.net"
  type = "A"
  ttl = "300"
  records = [aws_instance.collab.public_ip]
}


resource "aws_instance" "bastion" {
  ami = var.ami
  instance_type = var.bastion_instance_type
  subnet_id = var.subnet_public_id
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.bastion-sg.id ]
    associate_public_ip_address = true

  tags = {
    Name = "Bastion"
  }
}

resource "aws_security_group" "bastion-sg" {
  name = "bastion-security-group"
  vpc_id = var.vpc_id

  # Ping
  ingress {
    protocol = "icmp"
    from_port = 8
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = aws_route53_zone.primary.zone_id
  name = "bastion.kink.devium.net"
  type = "A"
  ttl = "300"
  records = [aws_instance.bastion.public_ip]
}
