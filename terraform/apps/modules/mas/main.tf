locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-inline' https://cdn.jsdelivr.net"
    "style-src"       = "'self' 'unsafe-inline' https://cdn.jsdelivr.net https://fonts.googleapis.com"
    "frame-ancestors" = "'self' https://${var.cluster_vars.domains.keycloak}"
  })
}

resource "kubernetes_secret_v1" "config" {
  metadata {
    name      = "mas-config"
    namespace = var.config.namespace
  }

  data = {
    "config.yaml" = <<-YAML
      clients:
        - client_id: 0000000000000000000SYNAPSE
          client_auth_method: client_secret_basic
          client_secret: ${var.config.secrets.client}

      http:
        listeners:
        - name: web
          resources:
          - name: discovery
          - name: human
          - name: oauth
          - name: compat
          - name: graphql
            playground: true
          - name: assets
            path: /usr/local/share/mas-cli/assets/
          binds:
          - address: '[::]:8080'
          proxy_protocol: false
        - name: internal
          resources:
          - name: health
          binds:
          - host: localhost
            port: 8081
          proxy_protocol: false

        trusted_proxies:
        - 192.128.0.0/16
        - 172.16.0.0/12
        - 10.0.0.0/10
        - 127.0.0.1/8
        - fd00::/8
        - ::1/128

        public_base: https://${local.fqdn}
        issuer: https://${var.cluster_vars.domains.domain}

      database:
        host: ${var.cluster_vars.db_host}
        port: 5432
        database: ${var.config.db.database}
        username: ${var.config.db.username}
        password: ${var.config.db.password}
        max_connections: 10
        min_connections: 0
        connect_timeout: 30
        idle_timeout: 600
        max_lifetime: 1800

      telemetry:
        tracing:
          exporter: none
          propagators: []
        metrics:
          exporter: none
        sentry:
          dsn: null

      templates:
        path: /usr/local/share/mas-cli/templates/
        assets_manifest: /usr/local/share/mas-cli/manifest.json
        translations_path: /usr/local/share/mas-cli/translations/

      email:
        from: '"Authentication Service" <root@localhost>'
        reply_to: '"Authentication Service" <root@localhost>'
        transport: blackhole

      secrets:
        encryption: ${var.config.secrets.encryption}
        keys:
        ${indent(2, yamlencode(var.config.secrets.keys))}

      passwords:
        enabled: false
        schemes:
        - version: 1
          algorithm: argon2id

      matrix:
        homeserver: ${var.cluster_vars.domains.domain}
        secret: ${var.config.secrets.admin_token}
        endpoint: https://${var.cluster_vars.domains.synapse}

      policy:
        wasm_module: /usr/local/share/mas-cli/policy.wasm
        client_registration_entrypoint: client_registration/violation
        register_entrypoint: register/violation
        authorization_grant_entrypoint: authorization_grant/violation
        password_entrypoint: password/violation
        email_entrypoint: email/violation

        data: 
          admin_users:
          ${indent(4, yamlencode(var.config.admins))}

          client_registration:
            allow_host_mismatch: true
            allow_missing_contacts: true

      upstream_oauth2:
        providers:
        - id: 000000000000000000KEYK10AK
          client_id: ${var.config.keycloak.client}
          client_secret: ${var.config.keycloak.secret}
          issuer: https://${var.cluster_vars.domains.keycloak}/realms/${var.cluster_vars.keycloak_realm}
          token_endpoint_auth_method: client_secret_basic
          scope: openid private_profile email

          claims_imports:
            localpart:
              action: require
              template: "{{ user.sub[:8] }}"
            displayname:
              action: require
              template: "{{ user.preferred_username }}"
            email:
              action: require
              template: "{{ user.email }}"
              set_email_verification: always

      branding:
        service_name: null
        policy_uri: null
        tos_uri: null
        imprint: null
        logo_uri: null

      experimental:
        access_token_ttl: 300
        compat_token_ttl: 300
    YAML
  }
}


resource "kubernetes_deployment_v1" "mas" {
  metadata {
    name      = "mas"
    namespace = var.config.namespace

    labels = {
      app = "mas"
    }
  }

  timeouts {
    create = "60s"
    update = "60s"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mas"
      }
    }

    template {
      metadata {
        labels = {
          app = "mas"
        }
      }

      spec {
        container {
          image = "ghcr.io/element-hq/matrix-authentication-service:${var.config.version}"
          name  = "mas"
          args = [
            "server"
          ]

          port {
            container_port = 8080
          }

          resources {
            requests = {
              memory = var.config.memory
            }
          }

          volume_mount {
            mount_path = "/config.yaml"
            name       = "config-volume"
            sub_path   = "config.yaml"
          }
        }

        init_container {
          image = "ghcr.io/element-hq/matrix-authentication-service:${var.config.version}"
          name  = "mas-migrate"
          args = [
            "database",
            "migrate"
          ]

          volume_mount {
            mount_path = "/config.yaml"
            name       = "config-volume"
            sub_path   = "config.yaml"
          }
        }

        init_container {
          image = "ghcr.io/element-hq/matrix-authentication-service:${var.config.version}"
          name  = "mas-config-sync"
          args = [
            "config",
            "sync",
            "--prune"
          ]

          volume_mount {
            mount_path = "/config.yaml"
            name       = "config-volume"
            sub_path   = "config.yaml"
          }
        }

        volume {
          name = "config-volume"
          secret {
            secret_name = one(kubernetes_secret_v1.config.metadata).name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "mas" {
  metadata {
    name      = "mas"
    namespace = var.config.namespace
  }

  spec {
    selector = {
      app = one(kubernetes_deployment_v1.mas.metadata).labels.app
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "mas" {
  metadata {
    name      = "mas"
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
              name = one(kubernetes_service_v1.mas.metadata).name

              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    rule {
      host = var.cluster_vars.domains.domain

      http {
        path {
          path      = "/.well-known/openid-configuration"
          path_type = "Exact"

          backend {
            service {
              name = one(kubernetes_service_v1.mas.metadata).name

              port {
                number = 8080
              }
            }
          }
        }

        # Comatibility layer for Matrix Authentication Service:
        # https://matrix-org.github.io/matrix-authentication-service/setup/reverse-proxy.html#example-nginx-configuration
        path {
          path      = "/_matrix/client/(.*)/(login|logout|refresh)"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = one(kubernetes_service_v1.mas.metadata).name

              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    rule {
      host = var.cluster_vars.domains.synapse

      http {
        # Comatibility layer for Matrix Authentication Service:
        # https://matrix-org.github.io/matrix-authentication-service/setup/reverse-proxy.html#example-nginx-configuration
        path {
          path      = "/_matrix/client/(.*)/(login|logout|refresh)"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = one(kubernetes_service_v1.mas.metadata).name

              port {
                number = 8080
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

    tls {
      secret_name = "${var.cluster_vars.domains.domain}-tls"

      hosts = [
        var.cluster_vars.domains.domain
      ]
    }

    tls {
      secret_name = "${var.cluster_vars.domains.synapse}-tls"

      hosts = [
        var.cluster_vars.domains.synapse
      ]
    }
  }
}
