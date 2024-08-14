locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "connect-src" = "wss: https:"
  })
}

resource "kubernetes_config_map_v1" "service_worker" {
  metadata {
    name      = "service-worker"
    namespace = var.config.namespace
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
  name      = var.cluster_vars.release_name
  namespace = var.config.namespace

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = var.config.version_nginx_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version_nginx}

    ingress:
      enabled: true
      tls: true
      certManager: true

      secrets: []

      pathType: Prefix
      hostname: ${local.fqdn}

      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

    resources:
      requests:
        memory: ${var.config.memory}

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
        image: ${var.config.site_image}
        imagePullPolicy: IfNotPresent

        command:
          - sh

        args:
          - -c
          - cp -R /html/* /html_volume/

        volumeMounts:
          - name: html
            mountPath: /html_volume

    metrics:
      enabled: true

      image:
        tag: ${var.config.version_nginx_prometheus_exporter}

      serviceMonitor:
        enabled: true
  YAML
  ]
}

resource "kubernetes_ingress_v1" "home_redirect" {
  metadata {
    name      = "home-redirect"
    namespace = var.config.namespace

    annotations = {
      "cert-manager.io/cluster-issuer"                 = var.cluster_vars.issuer
      "nginx.ingress.kubernetes.io/permanent-redirect" = "https://${local.fqdn}$uri"
      # Necessary so resolution is bucketed with Synapse's regex ingress.
      "nginx.ingress.kubernetes.io/use-regex" = "true"
    }
  }

  spec {
    rule {
      host = var.cluster_vars.domains.domain

      http {
        path {
          # End of string "$" is important lest this also catches /.*
          path      = "/(imprint|privacy)?$"
          path_type = "ImplementationSpecific"

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
      secret_name = "${var.cluster_vars.domains.domain}-tls"

      hosts = [
        var.cluster_vars.domains.domain
      ]
    }
  }
}
