locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    script-src = "'self' 'unsafe-inline' 'unsafe-eval' blob:"
  })
}

resource "kubernetes_secret_v1" "wiki" {
  metadata {
    name      = "${var.cluster_vars.release_name}-wiki"
    namespace = var.config.namespace
  }

  data = {
    "postgresql-password" = var.config.db.password
  }
}

resource "helm_release" "wiki" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://charts.js.wiki"
  chart      = "wiki"
  version    = var.config.version_helm
  timeout    = 120

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    ingress:
      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

      hosts:
        - host: ${local.fqdn}
          paths:
            - path: "/"
              pathType: Prefix

      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    resources:
      requests:
        memory: ${var.config.memory}

    postgresql:
      enabled: false
      postgresqlHost: ${var.cluster_vars.db_host}
      postgresqlDatabase: ${var.config.db.database}
      postgresqlUser: ${var.config.db.username}
      existingSecret: ${one(kubernetes_secret_v1.wiki.metadata).name}
  YAML
  ]
}
