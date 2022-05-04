locals {
  fqdn = "${var.subdomains.nextcloud}.${var.domain}"

  csp = merge(var.default_csp, {
    "script-src"      = "'self' 'unsafe-inline'"
    "frame-src"       = "'self' https://${var.subdomains.collabora}.${var.domain}"
    "frame-ancestors" = "'self'"
  })
}

resource "helm_release" "nextcloud" {
  name       = var.release_name
  namespace  = var.namespaces.nextcloud
  repository = "https://nextcloud.github.io/helm/"
  chart      = "nextcloud"
  version    = var.versions.nextcloud_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.nextcloud}

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"
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
        memory: ${var.resources.memory.nextcloud}

    nextcloud:
      host: ${local.fqdn}
      username: admin_temp
      password: ${var.admin_passwords.nextcloud}

      extraEnv:
        - name: OVERWRITEPROTOCOL
          value: https
        # Env values with NC_ prefix override config values, just in case they become outdated
        - name: NC_dbhost
          value: ${var.db_host}
        - name: NC_dbport
          value: "5432"
        - name: NC_dbname
          value: nextcloud
        - name: NC_dbuser
          valueFrom:
            secretKeyRef:
              name: ${var.release_name}-db
              key: db-username
        - name: NC_dbpassword
          valueFrom:
            secretKeyRef:
              name: ${var.release_name}-db
              key: db-password

    internalDatabase:
      enabled: false

    externalDatabase:
      enabled: true
      type: postgresql
      host: ${var.db_host}
      user: nextcloud
      password: ${var.db_passwords.nextcloud}
      database: nextcloud

    persistence:
      enabled: true
      existingClaim: ${var.pvcs.nextcloud}
  YAML
  ]
}
