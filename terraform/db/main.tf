resource "aws_security_group" "db-sg" {
  name = "db-security-group"
  vpc_id = var.vpc_id

  # PostgreSQL
  ingress {
    protocol = "tcp"
    from_port = 5432
    to_port = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "db" {
  allocated_storage = 5
  engine = "postgres"
  engine_version = "13.3"
  instance_class = "db.t3.micro"
  name = "kinkdb"
  username = var.db_username
  password = var.db_password
  multi_az = false
  storage_type = "gp2"
  skip_final_snapshot = false
  final_snapshot_identifier = "kinkdb-snapshot-final"
  snapshot_identifier = "kinkdb-snapshot-final"
  db_subnet_group_name = var.db_subnet_group_name
  vpc_security_group_ids = [ aws_security_group.db-sg.id ]
}
