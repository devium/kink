output "name" {
  value = var.name
}

output "ipv4_address" {
  value = hcloud_server.node.ipv4_address
}

output "ipv6_address" {
  value = hcloud_server.node.ipv6_address
}

output "id" {
  value = hcloud_server.node.id
}

output "taints" {
  value = var.taints
}
