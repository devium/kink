locals {
  namespace = "element"
}

resource "helm_release" "element" {
  name             = var.release_name
  namespace        = local.namespace
  create_namespace = true

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
        cert-manager.io/cluster-issuer: letsencrypt
      hosts:
        - host: ${var.subdomains.element}.${var.domain}
          paths:
            - /
      tls:
        - secretName: cert-secret
          hosts:
            - ${var.subdomains.element}.${var.domain}

    YAML
  ]
}