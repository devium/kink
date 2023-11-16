locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
}

resource "helm_release" "sliding_sync" {
  name      = "${var.cluster_vars.release_name}-sliding-sync"
  namespace = var.config.namespace

  repository = "https://ananace.gitlab.io/charts"
  chart      = "sliding-sync-proxy"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    matrixServer: https://${var.cluster_vars.domains.domain}

    resources:
      requests:
        memory: ${var.config.memory}

    ingress:
      enabled: true
      serveSimpleClient: true

      hosts:
        - ${local.fqdn}

      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"

      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    postgresql:
      enabled: false

    externalPostgresql:
      host: ${var.cluster_vars.db_host}
      sslmode: disable
      database: ${var.config.db.database}
      username: ${var.config.db.username}
      password: ${var.config.db.password}
  YAML
  ]
}
