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

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "30001"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "Minecraft"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "30002"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "Minecraft RCON"
  }

  # Mail stuff

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "25"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "SMTP"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "143"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "IMAP"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "587"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "SMTP-over-TLS"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "993"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    description = "IMAPS"
  }
}
