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

locals {
  root_subdomain = regex("^(.*?)\\.?[\\w-]+\\.\\w+$", var.domain)[0]
}

resource "hetznerdns_record" "root_ipv4" {
  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? "@" : local.root_subdomain
  value   = var.floating_ipv4
  type    = "A"
  ttl     = 300
}

resource "hetznerdns_record" "root_ipv6" {
  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? "@" : local.root_subdomain
  value   = var.floating_ipv6
  type    = "AAAA"
  ttl     = 300
}

resource "hetznerdns_record" "subdomain" {
  for_each = var.subdomains

  zone_id = var.hdns_zone_id
  name = local.root_subdomain == "" ? each.value : "${each.value}.${local.root_subdomain}"
  value = "${var.domain}."
  type = "CNAME"
  ttl = 300
}
