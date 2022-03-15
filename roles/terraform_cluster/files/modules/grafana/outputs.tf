output "loki_host" {
  value = "${helm_release.loki.name}.${helm_release.loki.namespace}"
}
