locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-eval'",
    "connect-src"     = "'self' https://${var.cluster_vars.domains.keycloak} https://${var.cluster_vars.domains.synapse} https://${var.cluster_vars.domains.domain} https://vector.im https://pingback.giphy.com https://scalar.vector.im wss:"
    "frame-src"       = "'self' https://${var.cluster_vars.domains.jitsi} https://${var.cluster_vars.domains.keycloak} https://${var.cluster_vars.domains.nextcloud} https://scalar.vector.im"
    "frame-ancestors" = "'self'"
  })
}

resource "helm_release" "element" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://ananace.gitlab.io/charts"
  chart      = "element-web"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    defaultServer:
      url: https://${var.cluster_vars.domains.domain}
      name: ${var.cluster_vars.domains.domain}
      identity_url: none

    config:
      default_theme: dark
      disable_custom_urls: true
      disable_guests: true

      settingDefaults:
        UIFeature.registration: false

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}

        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

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
