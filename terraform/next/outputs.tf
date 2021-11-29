output "instance_id" {
  value = aws_instance.next.id
}

output "private_ip" {
  value = aws_instance.next.private_ip
}
