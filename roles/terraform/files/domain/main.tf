terraform {
  required_providers {
    hetznerdns = {
      source = "timohirt/hetznerdns"
    }
  }
}

provider "hetznerdns" {
  apitoken = var.hdns_token
}

resource "hetznerdns_record" "root" {
  zone_id = var.hdns_zone_id
  name = var.root_subdomain
  value = var.floating_ipv4
  type = "A"
  ttl = 300
}
