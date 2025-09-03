locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "connect-src" = "wss: https:"
  })
}

resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name      = "nginx"
    namespace = var.config.namespace

    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        volume {
          name = "html"
          empty_dir {
          }
        }

        container {
          image = "nginx:${var.config.version_nginx}"
          name  = "nginx"

          port {
            container_port = 80
          }

          resources {
            requests = {
              memory = var.config.memory
            }
          }

          volume_mount {
            name       = "html"
            mount_path = "/usr/share/nginx/html"
          }
        }

        init_container {
          image             = var.config.site_image
          name              = "site"
          image_pull_policy = "IfNotPresent"
          command           = ["sh"]
          args              = ["-c", "cp -R /html/* /html_shared/"]

          volume_mount {
            name       = "html"
            mount_path = "/html_shared"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "home" {
  metadata {
    name      = "home"
    namespace = var.config.namespace
  }

  spec {
    selector = {
      app = one(kubernetes_deployment_v1.nginx.metadata).labels.app
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "home" {
  metadata {
    name      = "home"
    namespace = var.config.namespace

    annotations = {
      "cert-manager.io/cluster-issuer"                    = var.cluster_vars.issuer
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
              name = one(kubernetes_service_v1.home.metadata).name

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

resource "kubernetes_ingress_v1" "home_redirect" {
  metadata {
    name      = "home-redirect"
    namespace = var.config.namespace

    annotations = {
      "cert-manager.io/cluster-issuer" = var.cluster_vars.issuer
      # TODO: Add $uri back to the redirect URL, once this is fixed: https://github.com/kubernetes/ingress-nginx/issues/12709
      "nginx.ingress.kubernetes.io/permanent-redirect" = "https://${local.fqdn}"
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
              name = one(kubernetes_service_v1.home.metadata).name
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
