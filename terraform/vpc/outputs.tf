output "vpc_id" {
    value = aws_vpc.main.id
}

output "cidr_vpc" {
    value = aws_vpc.main.cidr_block
}

output "subnet_public_id" {
    value = aws_subnet.public.id
}

output "subnet_private_id" {
    value = aws_subnet.private.id
}

output "db_subnet_group_name" {
    value = aws_db_subnet_group.db_subnet.name
}
