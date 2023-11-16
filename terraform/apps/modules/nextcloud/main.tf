locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-inline'"
    "frame-src"       = "'self' https://${var.cluster_vars.domains.collabora}"
    "frame-ancestors" = "https:"
  })
}

resource "helm_release" "nextcloud" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://nextcloud.github.io/helm/"
  chart      = "nextcloud"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/proxy-body-size: 500m
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

      hosts:
        - host: ${local.fqdn}
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    resources:
      requests:
        memory: ${var.config.memory}

    nextcloud:
      host: ${local.fqdn}
      username: admin_temp
      password: ${var.config.admin_password}

      extraEnv:
        - name: OVERWRITEPROTOCOL
          value: https
        # Env values with NC_ prefix override config values, just in case they become outdated
        - name: NC_dbhost
          value: ${var.cluster_vars.db_host}
        - name: NC_dbport
          value: "5432"
        - name: NC_dbname
          value: nextcloud
        - name: NC_dbuser
          valueFrom:
            secretKeyRef:
              name: ${var.cluster_vars.release_name}-db
              key: db-username
        - name: NC_dbpassword
          valueFrom:
            secretKeyRef:
              name: ${var.cluster_vars.release_name}-db
              key: db-password

    internalDatabase:
      enabled: false

    externalDatabase:
      enabled: true
      type: postgresql
      host: ${var.cluster_vars.db_host}
      user: ${var.config.db.username}
      password: ${var.config.db.password}
      database: ${var.config.db.database}

    persistence:
      enabled: true
      existingClaim: nextcloud-pvc
  YAML
  ]
}
