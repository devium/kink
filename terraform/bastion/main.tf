resource "aws_instance" "bastion" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = var.subnet_public_id
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.bastion-sg.id ]
    associate_public_ip_address = true

  tags = {
    Name = "${var.identifier}-bastion"
  }
}

resource "aws_security_group" "bastion-sg" {
  name = "${var.identifier}-bastion"
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
  zone_id = var.zone_id
  name = "bastion.${var.domain}"
  type = "A"
  ttl = "300"
  records = [aws_instance.bastion.public_ip]
  depends_on = [aws_instance.bastion]
}
