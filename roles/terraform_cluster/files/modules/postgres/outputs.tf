output "host" {
  value = "${helm_release.postgres.name}-${helm_release.postgres.chart}.${helm_release.postgres.namespace}.svc.cluster.local"
}