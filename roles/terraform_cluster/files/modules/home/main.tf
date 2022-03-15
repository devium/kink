locals {
  fqdn = "${var.subdomains.home}.${var.domain}"
}

resource "helm_release" "home" {
  name      = var.release_name
  namespace = var.namespaces.home

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = var.versions.nginx_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.nginx}

    ingress:
      enabled: true
      tls: true
      certManager: true

      secrets: []

      pathType: Prefix
      hostname: ${local.fqdn}

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers 'Clear-Site-Data: "storage"';

    resources:
      requests:
        memory: ${var.resources.memory.home}

    service:
      type: ClusterIP

    extraVolumes:
      - name: html
        emptyDir: {}

    extraVolumeMounts:
      - name: html
        mountPath: /app

    initContainers:
      - name: site
        image: ${var.home_site_image}
        imagePullPolicy: IfNotPresent

        command:
          - sh

        args:
          - -c
          - cp -R /html/* /html_volume/

        volumeMounts:
          - name: html
            mountPath: /html_volume
  YAML
  ]
}

resource "kubernetes_ingress_v1" "home_redirect" {
  metadata {
    name      = "home-redirect"
    namespace = var.namespaces.home

    annotations = {
      "cert-manager.io/cluster-issuer"                 = var.cert_issuer
      "nginx.ingress.kubernetes.io/permanent-redirect" = "https://${local.fqdn}$uri"
    }
  }

  spec {
    rule {
      host = var.domain

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          # This is not used but required anyway
          backend {
            service {
              name = "${helm_release.home.name}-nginx"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      secret_name = "${var.domain}-tls"

      hosts = [
        var.domain
      ]
    }
  }
}
