locals {
  fqdn = "${var.subdomains.home}.${var.domain}"

  csp = merge(var.default_csp, {
    "connect-src" = "https://${var.subdomains.jitsi}.${var.domain} https://${var.subdomains.nextcloud}.${var.domain}"
  })
}

resource "kubernetes_config_map_v1" "service_worker" {
  metadata {
    name      = "service-worker"
    namespace = var.namespaces.home
  }

  data = {
    "service-worker.js" = <<-JS
      self.addEventListener('install', function(e) {
        self.skipWaiting();
      });

      self.addEventListener('activate', function(e) {
        self.registration.unregister()
          .then(function() {
            return self.clients.matchAll();
          })
          .then(function(clients) {
            clients.forEach(client => client.navigate(client.url))
          });
      });
    JS
  }
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
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

    resources:
      requests:
        memory: ${var.resources.memory.home}

    service:
      type: ClusterIP

    extraVolumes:
      - name: html
        emptyDir: {}
      - name: service-worker
        configMap:
          name: ${one(kubernetes_config_map_v1.service_worker.metadata).name}

    extraVolumeMounts:
      - name: html
        mountPath: /app
      - name: service-worker
        mountPath: /app/service-worker.js
        subPath: service-worker.js

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

resource "kubernetes_ingress_v1" "service_worker" {
  # Making the self-destructing service worker available directly on www and
  # the root domain is crucial to delete legacy service workers on both domains.
  metadata {
    name      = "service-worker"
    namespace = var.namespaces.home

    annotations = {
      "cert-manager.io/cluster-issuer" = var.cert_issuer
    }
  }

  spec {
    rule {
      host = var.domain

      http {
        path {
          path      = "/service-worker.js"
          path_type = "Exact"

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
          path_type = "Exact"

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
