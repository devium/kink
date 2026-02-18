terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
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

  dkim_despaced = replace(file(var.dkim_file), "/[\\s|\"]/", "")
  dkim_trimmed  = regex("\\((.*)\\)", local.dkim_despaced)[0]

  dmarc = "v=DMARC1; p=quarantine; rua=mailto:dmarc.report@${var.domain}; ruf=mailto:dmarc.report@${var.domain}; sp=quarantine; ri=86400"
}

resource "hcloud_zone" "zone" {
  name = "${var.domain}"
  mode = "primary"
  ttl  = 300
}

resource "hcloud_zone_rrset" "node_ipv4" {
  count = length(local.node_domains)

  zone = hcloud_zone.zone.name
  name = local.node_domains[count.index].subdomain
  type = "A"

  records = [{
    value = local.node_domains[count.index].ipv4_address
  }]
}

resource "hcloud_zone_rrset" "node_ipv6" {
  count = length(local.node_domains)

  zone = hcloud_zone.zone.name
  name = local.node_domains[count.index].subdomain
  type = "AAAA"

  records = [{
    value = local.node_domains[count.index].ipv6_address
  }]
}

resource "hcloud_zone_rrset" "root_ipv4" {
  zone = hcloud_zone.zone.name
  name = local.root_subdomain == "" ? "@" : local.root_subdomain
  type = "A"

  records = [{
    value = var.nodes[0].ipv4_address
  }]
}

resource "hcloud_zone_rrset" "root_ipv6" {
  zone = hcloud_zone.zone.name
  name = local.root_subdomain == "" ? "@" : local.root_subdomain
  type = "AAAA"

  records = [{
    value = var.nodes[0].ipv6_address
  }]
}

resource "hcloud_zone_rrset" "subdomain" {
  for_each = var.subdomains

  zone = hcloud_zone.zone.name
  name = local.root_subdomain == "" ? each.value : "${each.value}.${local.root_subdomain}"
  type    = "CNAME"

  records = [{
    value = "${var.domain}."
  }]
}

resource "hcloud_zone_rrset" "dkim" {
  zone = hcloud_zone.zone.name
  name = local.root_subdomain == "" ? "mail._domainkey" : "mail._domainkey.${local.root_subdomain}"
  type = "TXT"

  records = [{
    value = provider::hcloud::txt_record(local.dkim_trimmed)
  }]
}

resource "hcloud_zone_rrset" "mx" {
  zone = hcloud_zone.zone.name
  name = local.root_subdomain == "" ? "@" : local.root_subdomain
  type = "MX"

  records = [{
    value = "1 ${var.subdomains.mailserver}.${var.domain}."
  }]
}

resource "hcloud_zone_rrset" "spf" {
  zone = hcloud_zone.zone.name
  name = local.root_subdomain == "" ? "@" : local.root_subdomain
  type = "TXT"

  records = [{
    value = provider::hcloud::txt_record(local.spf)
  }]
}

resource "hcloud_zone_rrset" "dmarc" {
  zone = hcloud_zone.zone.name
  name = local.root_subdomain == "" ? "_dmarc" : "_dmarc.${local.root_subdomain}"
  type = "TXT"

  records = [{
    value = provider::hcloud::txt_record(local.dmarc)
  }]
}
