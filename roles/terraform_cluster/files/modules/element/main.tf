locals {
  fqdn = "${var.subdomains.element}.${var.domain}"
}

resource "helm_release" "element" {
  name       = var.release_name
  namespace  = var.namespaces.element
  repository = "https://halkeye.github.io/helm-charts/"
  chart      = "element-web"
  version    = var.versions.element_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.element}

    configjson:
      default_server_name: ${var.domain}
      disable_custom_urls: true
      disable_guests: true
      default_theme: dark

      sso_redirect_options:
        immediate: true

      settingDefaults:
        UIFeature.registration: false

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}

      hosts:
        - host: ${local.fqdn}
          paths:
            - /
      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    YAML
  ]
}