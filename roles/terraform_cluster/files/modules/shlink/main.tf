locals {
  fqdn     = "${var.subdomains.shlink}.${var.domain}"
  fqdn_web = "${var.subdomains.shlink_web}.${var.domain}"
}

resource "helm_release" "shlink" {
  name      = var.release_name
  namespace = var.namespaces.shlink

  repository = "https://k8s-at-home.com/charts/"
  chart      = "shlink"
  version    = var.versions.shlink_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.shlink}

    ingress:
      main:
        enabled: true

        annotations:
          cert-manager.io/cluster-issuer: ${var.cert_issuer}

        hosts:
          - host: ${var.domain}
            paths:
              - path: /
                pathType: Prefix
          - host: ${local.fqdn}
            paths:
              - path: /
                pathType: Prefix

        tls:
          - secretName: ${var.domain}-tls
            hosts:
              - ${var.domain}
          - secretName: ${local.fqdn}-tls
            hosts:
              - ${local.fqdn}

    resources:
      requests:
        memory: ${var.resources.memory.shlink}

    secret:
      DB_PASSWORD: ${var.db_passwords.shlink}

    env:
      DEFAULT_DOMAIN: "${var.domain}"
      SHORT_DOMAIN_SCHEMA: https
      DB_PASSWORD:
        valueFrom:
          secretKeyRef:
            name: ${var.release_name}-shlink
            key: DB_PASSWORD
      DB_DRIVER: postgres
      DB_NAME: shlink
      DB_USER: shlink
      DB_HOST: ${var.db_host}
  YAML
  ]
}

resource "kubernetes_deployment_v1" "web" {
  metadata {
    name      = "shlink-web"
    namespace = var.namespaces.shlink

    labels = {
      app = "shlink-web"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "shlink-web"
      }
    }

    template {
      metadata {
        labels = {
          app = "shlink-web"
        }
      }

      spec {
        container {
          image = "shlinkio/shlink-web-client:${var.versions.shlink_web}"
          name  = "shlink-web"

          port {
            container_port = 80
          }

          resources {
            requests = {
              memory = var.resources.memory.shlink_web
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "web" {
  metadata {
    name      = "shlink-web"
    namespace = var.namespaces.shlink
  }

  spec {
    selector = {
      app = one(kubernetes_deployment_v1.web.metadata).labels.app
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "web" {
  metadata {
    name      = "shlink-web"
    namespace = var.namespaces.shlink

    annotations = {
      "cert-manager.io/cluster-issuer"                = var.cert_issuer
      "nginx.ingress.kubernetes.io/enable-cors"       = "true"
      "nginx.ingress.kubernetes.io/cors-allow-origin" = "https://${local.fqdn}/*"
    }
  }

  spec {
    rule {
      host = local.fqdn_web

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = one(kubernetes_service_v1.web.metadata).name

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      secret_name = "${local.fqdn_web}-tls"

      hosts = [
        local.fqdn_web
      ]
    }
  }
}
