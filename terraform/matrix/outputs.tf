output "instance_id" {
  value = aws_instance.matrix.id
}

output "public_ip" {
  value = aws_instance.matrix.public_ip
}

output "private_ip" {
  value = aws_instance.matrix.private_ip
}
