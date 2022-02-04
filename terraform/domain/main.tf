resource "aws_route53_zone" "primary" {
  name = var.domain
}

resource "aws_route53_record" "floating" {
  zone_id = aws_route53_zone.primary.zone_id
  name = var.domain
  type = "A"
  ttl = "300"
  records = [var.floating_ipv4]
}
