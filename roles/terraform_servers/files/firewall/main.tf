terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

resource "hcloud_firewall" "firewall" {
  name = "firewall"

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "Ping"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "SSH"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "HTTP"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "HTTPS"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "Kubernetes API"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "9345"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "Kubernetes API"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "10250"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "RKE2 metrics server"
  }

  rule {
    direction = "in"
    protocol  = "udp"
    port      = "30000"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "Jitsi JVB"
  }
}
