output "collab_private_ip" {
  value = aws_instance.collab.private_ip
}

output "bastion_hostname" {
  value = aws_route53_record.bastion.name
}
