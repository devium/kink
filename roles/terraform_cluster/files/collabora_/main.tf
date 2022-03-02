locals {
  namespace = "collabora"
}

resource "helm_release" "collabora" {
  name             = var.release_name
  namespace        = local.namespace
  create_namespace = true

  repository = "https://chrisingenhaag.github.io/helm/"
  chart      = "collabora-code"
  version    = var.versions.collabora_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.collabora}

    collabora:
      domain: ${replace("${var.subdomains.nextcloud}.${var.domain}", ".", "\\\\.")}
      server_name: ${var.subdomains.collabora}.${var.domain}
      username: admin
      password: ${var.admin_passwords.collabora}

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt

      paths:
        - /
      hosts:
        - ${var.subdomains.collabora}.${var.domain}
      tls:
        - secretName: cert-secret
          hosts:
            - ${var.subdomains.collabora}.${var.domain}

    YAML
  ]
}
