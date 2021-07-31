output "instance_id" {
  value = aws_instance.auth.id
}

output "private_ip" {
  value = aws_instance.auth.private_ip
}
