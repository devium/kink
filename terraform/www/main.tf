resource "aws_route53_record" "apex" {
  zone_id = var.zone_id
  name = "${var.domain}"
  type = "A"
  ttl = "300"
  records = [var.public_ip]
}

resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  name = "www.${var.domain}"
  type = "CNAME"
  ttl = "300"
  records = [aws_route53_record.apex.name]
  depends_on = [aws_route53_record.apex]
}
