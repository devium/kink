locals {
  fqdn     = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
  oidc_url = "/realms/${var.cluster_vars.keycloak_realm}/protocol/openid-connect"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-eval'"
    "frame-ancestors" = "*"
  })
}

resource "kubernetes_secret_v1" "config" {
  metadata {
    name      = "config"
    namespace = var.config.namespace
  }

  data = {
    "pretix.cfg" = <<-CFG
      [pretix]
      instance_name=${var.cluster_vars.domains.domain}
      url=https://${local.fqdn}
      currency=EUR
      datadir=/data

      [mail]
      from=${var.config.mail.account}@${var.cluster_vars.domains.domain}
      host=${var.cluster_vars.mail_server}
      user=${var.config.mail.account}@${var.cluster_vars.domains.domain}
      password=${var.config.mail.password}
      port=587
      tls=True

      [django]
      debug=false

      [database]
      backend=postgresql_psycopg2
      name=${var.config.db.database}
      user=${var.config.db.username}
      password=${var.config.db.password}
      host=${var.cluster_vars.db_host}

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
    namespace = var.config.namespace

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
          image             = "pretix/standalone:${var.config.version}"
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
              memory = var.config.memory
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
              memory = var.config.memory_redis
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
            claim_name = "pretix-pvc"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "pretix" {
  metadata {
    name      = "pretix"
    namespace = var.config.namespace
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
    namespace = var.config.namespace

    annotations = {
      "cert-manager.io/cluster-issuer"                    = var.cluster_vars.issuer
      "nginx.ingress.kubernetes.io/proxy-body-size"       = "10M"
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
