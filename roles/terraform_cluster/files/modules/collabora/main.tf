locals {
  fqdn = "${var.subdomains.collabora}.${var.domain}"
}

resource "helm_release" "collabora" {
  name       = var.release_name
  namespace  = var.namespaces.collabora
  repository = "https://chrisingenhaag.github.io/helm/"
  chart      = "collabora-code"
  version    = var.versions.collabora_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.collabora}

    collabora:
      domain: ${replace("${var.subdomains.nextcloud}.${var.domain}", ".", "\\\\.")}
      server_name: ${local.fqdn}
      username: admin
      password: ${var.admin_passwords.collabora}

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}

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
        memory: ${var.resources.memory.collabora}
  YAML
  ]
}
