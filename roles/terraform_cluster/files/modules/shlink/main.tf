locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
}

resource "helm_release" "shlink" {
  name      = var.cluster_vars.release_name
  namespace = var.config.namespace

  repository = "https://k8s-at-home.com/charts/"
  chart      = "shlink"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    ingress:
      main:
        enabled: true

        annotations:
          cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}

        hosts:
          - host: ${var.cluster_vars.domains.domain}
            paths:
              - path: /
                pathType: Prefix
          - host: ${local.fqdn}
            paths:
              - path: /
                pathType: Prefix

        tls:
          - secretName: ${var.cluster_vars.domains.domain}-tls
            hosts:
              - ${var.cluster_vars.domains.domain}
          - secretName: ${local.fqdn}-tls
            hosts:
              - ${local.fqdn}

    resources:
      requests:
        memory: ${var.config.memory}

    secret:
      DB_PASSWORD: ${var.config.db.password}

    env:
      DEFAULT_DOMAIN: "${var.cluster_vars.domains.domain}"
      SHORT_DOMAIN_SCHEMA: https
      DB_PASSWORD:
        valueFrom:
          secretKeyRef:
            name: ${var.cluster_vars.release_name}-shlink
            key: DB_PASSWORD
      DB_DRIVER: postgres
      DB_NAME: ${var.config.db.database}
      DB_USER: ${var.config.db.username}
      DB_HOST: ${var.cluster_vars.db_host}
  YAML
  ]
}
