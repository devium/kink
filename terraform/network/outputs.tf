output "network_id" {
  value = hcloud_network.network.id
}

output "floating_ipv4" {
  value = hcloud_floating_ip.floating_ipv4.ip_address
}

output "floating_ipv6" {
  value = hcloud_floating_ip.floating_ipv6.ip_address
}
