locals {
  fqdn     = "${var.subdomains.pretix}.${var.domain}"
  oidc_url = "/realms/${var.keycloak_realm}/protocol/openid-connect"
}

resource "kubernetes_secret_v1" "config" {
  metadata {
    name      = "config"
    namespace = var.namespaces.pretix
  }

  data = {
    "pretix.cfg" = <<-CFG
      [pretix]
      instance_name=${var.domain}
      url=https://${local.fqdn}
      currency=EUR
      datadir=/data

      [mail]
      from=
      host=
      user=
      password=
      port=2525
      tls=True

      [django]
      debug=false

      [database]
      backend=postgresql_psycopg2
      name=pretix
      user=pretix
      password=${var.db_passwords.pretix}
      host=${var.db_host}

      [redis]
      location=redis://localhost/0
      sessions=true

      [celery]
      backend=redis://localhost/1
      broker=redis://localhost/2
    CFG
  }
}

resource "kubernetes_deployment_v1" "pretix" {
  metadata {
    name      = "pretix"
    namespace = var.namespaces.pretix

    labels = {
      app = "pretix"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "pretix"
      }
    }

    template {
      metadata {
        labels = {
          app = "pretix"
        }
      }

      spec {
        container {
          image             = "pretix/standalone:${var.versions.pretix}"
          name              = "pretix"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/pretix/pretix.cfg"
            sub_path   = "pretix.cfg"
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
            sub_path   = "data"
          }

          resources {
            requests = {
              memory = var.resources.memory.pretix
            }
          }
        }

        container {
          image             = "redis:latest"
          name              = "redis"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 6379
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/run/redis"
            sub_path   = "redis"
          }

          resources {
            requests = {
              memory = var.resources.memory.pretix_redis
            }
          }
        }

        security_context {
          fs_group = 15371
        }

        volume {
          name = "config"
          secret {
            secret_name = one(kubernetes_secret_v1.config.metadata).name
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = var.pvcs.pretix
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "pretix" {
  metadata {
    name      = "pretix"
    namespace = var.namespaces.pretix
  }

  spec {
    selector = {
      app = one(kubernetes_deployment_v1.pretix.metadata).labels.app
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "pretix" {
  metadata {
    name      = "pretix"
    namespace = var.namespaces.pretix

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
              name = one(kubernetes_service_v1.pretix.metadata).name

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
