locals {
  fqdn = "${var.subdomains.homer}.${var.domain}"

  config_file = templatefile(
    "${path.module}/config.yml.tftpl",
    {
      title               = title(var.project_name)
      subdomain_homer     = var.subdomains.homer
      subdomain_keycloak  = var.subdomains.keycloak
      subdomain_hedgedoc  = var.subdomains.hedgedoc
      subdomain_element   = var.subdomains.element
      subdomain_jitsi     = var.subdomains.jitsi
      subdomain_nextcloud = var.subdomains.nextcloud
      domain              = var.domain
      keycloak_realm      = var.keycloak_realm
    }
  )

  rooms_file = templatefile(
    "${path.module}/rooms.html.tftpl",
    {
      jitsi_domain = "${var.subdomains.jitsi}.${var.domain}"
    }
  )
}

resource "kubernetes_config_map_v1" "config" {
  metadata {
    name      = "config"
    namespace = var.namespaces.homer
  }

  data = {
    "config.yml" = <<-YAML
      ${local.config_file}
    YAML

    "rooms.html" = <<-YAML
      ${local.rooms_file}
    YAML

    "manifest.json" = ""
  }
}

resource "kubernetes_deployment_v1" "homer" {
  metadata {
    name      = "homer"
    namespace = var.namespaces.homer

    labels = {
      app = "homer"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "homer"
      }
    }

    template {
      metadata {
        labels = {
          app = "homer"
        }
      }

      spec {
        init_container {
          name              = "homer-assets"
          image             = var.homer_assets_image
          image_pull_policy = "Always"

          command = [
            "sh"
          ]

          args = [
            "-c",
            "cp -R /assets/* /assets_volume"
          ]

          volume_mount {
            name       = "assets"
            mount_path = "/assets_volume"
          }
        }

        container {
          name  = "homer"
          image = "b4bz/homer:${var.versions.homer}"

          port {
            container_port = 8080
          }

          volume_mount {
            name       = "assets"
            mount_path = "/www/assets"
          }

          volume_mount {
            name       = "config"
            mount_path = "/www/config.yml"
            sub_path   = "config.yml"
          }

          volume_mount {
            name       = "config"
            mount_path = "/www/rooms.html"
            sub_path   = "rooms.html"
          }

          # Disable service worker caching
          volume_mount {
            name       = "config"
            mount_path = "/www/assets/manifest.json"
            sub_path   = "manifest.json"
          }
        }

        volume {
          name = "assets"
          empty_dir {
          }
        }

        volume {
          name = "config"
          config_map {
            name = "config"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "homer" {
  metadata {
    name      = "homer"
    namespace = var.namespaces.homer
  }

  spec {
    selector = {
      app = one(kubernetes_deployment_v1.homer.metadata).labels.app
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "homer_redirect" {
  metadata {
    name      = "homer-redirect"
    namespace = var.namespaces.homer

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

          backend {
            service {
              name = one(kubernetes_service_v1.homer.metadata).name

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

resource "kubernetes_ingress_v1" "homer" {
  metadata {
    name      = "homer"
    namespace = var.namespaces.homer

    annotations = {
      "cert-manager.io/cluster-issuer" = var.cert_issuer
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
              name = one(kubernetes_service_v1.homer.metadata).name

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
