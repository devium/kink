locals {
  fqdn = "${var.subdomains.element}.${var.domain}"
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

      sso_redirect_options:
        immediate: true

      settingDefaults:
        UIFeature.registration: false

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: frame-ancestors https://*.${var.domain}";

      hosts:
        - ${local.fqdn}

      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}
  YAML
  ]
}