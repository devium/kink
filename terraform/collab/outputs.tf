output "instance_id" {
  value = aws_instance.collab.id
}

output "private_ip" {
  value = aws_instance.collab.private_ip
}
