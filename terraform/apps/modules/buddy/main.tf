locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"  = "'self' 'unsafe-eval'"
    "connect-src" = "'self' data:"
  })
}

resource "kubernetes_deployment_v1" "buddy" {
  metadata {
    name      = "buddy"
    namespace = var.config.namespace

    labels = {
      app = "buddy"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "buddy"
      }
    }

    template {
      metadata {
        labels = {
          app = "buddy"
        }
      }

      spec {
        container {
          image = "ghcr.io/amberbyte/consumption_buddy:${var.config.version}"
          name  = "buddy"

          port {
            container_port = 80
          }

          resources {
            requests = {
              memory = var.config.memory
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "buddy" {
  metadata {
    name      = "buddy"
    namespace = var.config.namespace
  }

  spec {
    selector = {
      app = one(kubernetes_deployment_v1.buddy.metadata).labels.app
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "buddy" {
  metadata {
    name      = "buddy"
    namespace = var.config.namespace

    annotations = {
      "cert-manager.io/cluster-issuer"                = var.cluster_vars.issuer
      "nginx.ingress.kubernetes.io/enable-cors"       = "true"
      "nginx.ingress.kubernetes.io/cors-allow-origin" = "https://${local.fqdn}"

      "nginx.ingress.kubernetes.io/configuration-snippet" = <<-CONF
        more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";
      CONF
    }
  }

  spec {
    rule {
      host = local.fqdn

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = one(kubernetes_service_v1.buddy.metadata).name

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      secret_name = "${local.fqdn}-tls"

      hosts = [
        local.fqdn
      ]
    }
  }
}
