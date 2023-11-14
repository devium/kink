locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"  = "'self' 'unsafe-inline' 'unsafe-eval'"
    "connect-src" = "'self' https://${var.cluster_vars.domains.shlink} wss:"
  })
}

resource "kubernetes_deployment_v1" "web" {
  metadata {
    name      = "shlink-web"
    namespace = var.config.namespace

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
          image = "shlinkio/shlink-web-client:${var.config.version}"
          name  = "shlink-web"

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

resource "kubernetes_service_v1" "web" {
  metadata {
    name      = "shlink-web"
    namespace = var.config.namespace
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
    namespace = var.config.namespace

    annotations = {
      "cert-manager.io/cluster-issuer"                = var.cluster_vars.issuer
      "nginx.ingress.kubernetes.io/enable-cors"       = "true"
      "nginx.ingress.kubernetes.io/cors-allow-origin" = "https://${var.cluster_vars.domains.shlink}"

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
      secret_name = "${local.fqdn}-tls"

      hosts = [
        local.fqdn
      ]
    }
  }
}
