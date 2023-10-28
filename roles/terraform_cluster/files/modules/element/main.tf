locals {
  fqdn = "${var.subdomains.element}.${var.domain}"

  csp = merge(var.default_csp, {
    "script-src"      = "'self' 'unsafe-eval'",
    "connect-src"     = "'self' https://${var.subdomains.keycloak}.${var.domain} https://${var.subdomains.synapse}.${var.domain} https://${var.domain} https://vector.im https://pingback.giphy.com https://scalar.vector.im wss:"
    "frame-src"       = "'self' https://${var.subdomains.jitsi}.${var.domain} https://${var.subdomains.keycloak}.${var.domain} https://${var.subdomains.nextcloud}.${var.domain} https://scalar.vector.im"
    "frame-ancestors" = "'self'"
  })
}

resource "helm_release" "element" {
  name       = var.release_name
  namespace  = var.namespaces.element
  repository = "https://ananace.gitlab.io/charts"
  chart      = "element-web"
  version    = var.versions.element_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.element}

    defaultServer:
      url: https://${var.domain}
      name: ${var.domain}

    config:
      default_theme: dark
      disable_custom_urls: true
      disable_guests: true

      settingDefaults:
        UIFeature.registration: false

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}

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
        memory: ${var.resources.memory.element}
  YAML
  ]
}
