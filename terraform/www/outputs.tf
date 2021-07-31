output "instance_id" {
  value = aws_instance.www.id
}

output "private_ip" {
  value = aws_instance.www.private_ip
}
