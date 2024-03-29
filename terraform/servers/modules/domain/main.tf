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

  node_domains = [
    for node in var.nodes :
    {
      name : node.name
      subdomain : local.root_subdomain == "" ? node.name : "${node.name}.${local.root_subdomain}"
      ipv4_address : node.ipv4_address
      ipv6_address : node.ipv6_address
    }
  ]

  spf = join(" ", concat(
    [
      "v=spf1"
    ],
    [
      for node_domain in local.node_domains :
      "ip4:${node_domain.ipv4_address} ip6:${node_domain.ipv6_address}"
    ],
    [
      "~all"
    ]
  ))
  # Split into quoted 256 character chunks so it matches Hetzner's representation of the record.
  spf_split = join(" ", [for i in range(0, length(local.spf), 255) : "\"${substr(local.spf, i, 255)}\""])

  dkim_despaced = replace(file(var.dkim_file), "/[\\s|\"]/", "")
  dkim_trimmed  = regex("\\((.*)\\)", local.dkim_despaced)[0]
  # Split into quoted 256 character chunks so it matches Hetzner's representation of the record.
  dkim_split = join(" ", [for i in range(0, length(local.dkim_trimmed), 255) : "\"${substr(local.dkim_trimmed, i, 255)}\""])

  dmarc = "v=DMARC1; p=quarantine; rua=mailto:dmarc.report@${var.domain}; ruf=mailto:dmarc.report@${var.domain}; sp=quarantine; ri=86400"
  # Split into quoted 256 character chunks so it matches Hetzner's representation of the record.
  dmarc_split = join(" ", [for i in range(0, length(local.dmarc), 255) : "\"${substr(local.dmarc, i, 255)}\""])
}

resource "hetznerdns_record" "node_ipv4" {
  count = length(local.node_domains)

  zone_id = var.hdns_zone_id
  name    = local.node_domains[count.index].subdomain
  value   = local.node_domains[count.index].ipv4_address
  type    = "A"
  ttl     = 300
}

resource "hetznerdns_record" "node_ipv6" {
  count = length(local.node_domains)

  zone_id = var.hdns_zone_id
  name    = local.node_domains[count.index].subdomain
  value   = local.node_domains[count.index].ipv6_address
  type    = "AAAA"
  ttl     = 300
}

resource "hetznerdns_record" "root_ipv4" {
  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? "@" : local.root_subdomain
  value   = var.nodes[0].ipv4_address
  type    = "A"
  ttl     = 300
}

resource "hetznerdns_record" "root_ipv6" {
  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? "@" : local.root_subdomain
  value   = var.nodes[0].ipv6_address
  type    = "AAAA"
  ttl     = 300
}

resource "hetznerdns_record" "subdomain" {
  for_each = var.subdomains

  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? each.value : "${each.value}.${local.root_subdomain}"
  value   = "${var.domain}."
  type    = "CNAME"
  ttl     = 300
}

resource "hetznerdns_record" "dkim" {
  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? "mail._domainkey" : "mail._domainkey.${local.root_subdomain}"
  # Trailing space is intentional to match Hetzner's representation of the record.
  value = "${local.dkim_split} "
  type  = "TXT"
  ttl   = 300
}

resource "hetznerdns_record" "mx" {
  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? "@" : local.root_subdomain
  value   = "1 ${var.subdomains.mailserver}.${var.domain}."
  type    = "MX"
  ttl     = 300
}

resource "hetznerdns_record" "spf" {
  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? "@" : local.root_subdomain
  # Trailing space is intentional to match Hetzner's representation of the record.
  value = "${local.spf_split} "
  type  = "TXT"
  ttl   = 300
}

resource "hetznerdns_record" "dmarc" {
  zone_id = var.hdns_zone_id
  name    = local.root_subdomain == "" ? "_dmarc" : "_dmarc.${local.root_subdomain}"
  value   = local.dmarc_split
  type    = "TXT"
  ttl     = 300
}
