locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-inline'"
    "frame-src"       = "'self' blob:"
    "frame-ancestors" = "https://${var.cluster_vars.domains.nextcloud}"
  })
}

resource "helm_release" "collabora" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://chrisingenhaag.github.io/helm/"
  chart      = "collabora-code"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    collabora:
      domain: ${replace("${var.cluster_vars.domains.nextcloud}", ".", "\\\\.")}
      server_name: ${local.fqdn}
      username: admin
      password: ${var.config.admin_password}

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

      paths:
        - /
      hosts:
        - ${local.fqdn}
      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    resources:
      requests:
        memory: ${var.config.memory}
  YAML
  ]
}
