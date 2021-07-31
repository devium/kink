output "instance_id" {
  value = aws_db_instance.db.id
}

output "private_address" {
  value = aws_db_instance.db.address
}
