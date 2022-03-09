locals {
  fqdn                = "${var.subdomains.jitsi}.${var.domain}"
  fqdn_jitsi_keycloak = "${var.subdomains.jitsi_keycloak}.${var.domain}"
}

resource "kubernetes_config_map_v1" "prosody_plugins" {
  metadata {
    name      = "prosody-plguins"
    namespace = var.namespaces.jitsi
  }

  data = {
    "mod_muc_rooms.lua" = <<-LUA
      ${file("${path.module}/mod_muc_rooms.lua")}
    LUA
  }
}

resource "helm_release" "jitsi" {
  name       = var.release_name
  namespace  = var.namespaces.jitsi
  repository = "https://jitsi-contrib.github.io/jitsi-helm/"
  chart      = "jitsi-meet"
  version    = var.versions.jitsi_helm

  values = [<<-YAML
    publicURL: https://${local.fqdn}
    enableAuth: true

    web:
      image:
        tag: ${var.versions.jitsi}

      ingress:
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: ${var.cert_issuer}
          nginx.ingress.kubernetes.io/enable-cors: "true"
          nginx.ingress.kubernetes.io/cors-allow-origin: https://*.${var.domain}
          nginx.ingress.kubernetes.io/configuration-snippet: |
            more_set_headers "Content-Security-Policy: frame-ancestors https://*.${var.domain}";

        enabled: true

        hosts:
          - host: ${local.fqdn}
            paths:
              - /

        tls:
          - secretName: ${local.fqdn}-tls
            hosts:
              - ${local.fqdn}

      extraEnvs:
        TOKEN_AUTH_URL: https://${local.fqdn_jitsi_keycloak}/{room}

    jvb:
      image:
        tag: ${var.versions.jitsi}

      service:
        enabled: true
        type: NodePort

      UDPPort: 30000

      xmpp:
        password: ${var.jitsi_secrets.jvb}

    jicofo:
      image:
        tag: ${var.versions.jitsi}

      xmpp:
        password: ${var.jitsi_secrets.jicofo}

    prosody:
      image:
        tag: ${var.versions.jitsi}

      persistence:
        enabled: false

      extraEnvs:
        - name: XMPP_MODULES
          value: muc_rooms
        - name: AUTH_TYPE
          value: jwt
        - name: JWT_APP_ID
          value: jitsi
        - name: JWT_APP_SECRET
          value: ${var.jitsi_secrets.jwt}

      extraVolumeMounts:
        - name: prosody-plugins
          mountPath: /prosody-plugins-custom

      extraVolumes:
        - name: prosody-plugins
          configMap:
            name: ${one(kubernetes_config_map_v1.prosody_plugins.metadata).name}

      ingress:
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: ${var.cert_issuer}

        enabled: true

        hosts:
          - host: ${local.fqdn}
            paths:
              - /rooms

        tls:
          - secretName: ${local.fqdn}-tls
            hosts:
              - ${local.fqdn}
  YAML
  ]
}

resource "kubernetes_secret_v1" "jitsi_keycloak_config" {
  metadata {
    name      = "jitsi-keycloak-config"
    namespace = var.namespaces.jitsi
  }

  data = {
    "keycloak.json" = <<-JSON
      {
        "realm": "${var.keycloak_realm}",
        "auth-server-url": "https://${var.subdomains.keycloak}.${var.domain}/auth/",
        "ssl-required": "external",
        "resource": "${var.keycloak_clients.jitsi}",
        "public-client": true,
        "credentials": {
          "secret": "${var.jitsi_secrets.jwt}"
        },
        "confidential-port": 0
      }
    JSON
  }
}

resource "kubernetes_deployment_v1" "jitsi_keycloak" {
  metadata {
    name      = "jitsi-keycloak"
    namespace = var.namespaces.jitsi

    labels = {
      app = "jitsi-keycloak"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "jitsi-keycloak"
      }
    }

    template {
      metadata {
        labels = {
          app = "jitsi-keycloak"
        }
      }

      spec {
        container {
          image = "ghcr.io/devium/jitsi-keycloak:${var.versions.jitsi_keycloak}"
          name  = "jitsi-keycloak"

          port {
            container_port = 3000
          }

          env {
            name  = "JITSI_SECRET"
            value = var.jitsi_secrets.jwt
          }
          env {
            name  = "DEFAULT_ROOM"
            value = "meeting"
          }
          env {
            name  = "JITSI_URL"
            value = "https://${local.fqdn}/"
          }
          env {
            name  = "JITSI_SUB"
            value = local.fqdn
          }

          volume_mount {
            name       = "keycloak-config"
            mount_path = "/config/keycloak.json"
            sub_path   = "keycloak.json"
          }
        }

        volume {
          name = "keycloak-config"
          secret {
            secret_name = one(kubernetes_secret_v1.jitsi_keycloak_config.metadata).name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "jitsi_keycloak" {
  metadata {
    name      = "jitsi-keycloak"
    namespace = var.namespaces.jitsi
  }

  spec {
    selector = {
      app = one(kubernetes_deployment_v1.jitsi_keycloak.metadata).labels.app
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 3000
    }
  }
}

resource "kubernetes_ingress_v1" "jitsi_keycloak" {
  metadata {
    name      = "jitsi-keycloak"
    namespace = var.namespaces.jitsi

    annotations = {
      "cert-manager.io/cluster-issuer" = var.cert_issuer
    }
  }

  spec {
    rule {
      host = local.fqdn_jitsi_keycloak

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = one(kubernetes_service_v1.jitsi_keycloak.metadata).name

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      secret_name = "${local.fqdn_jitsi_keycloak}-tls"

      hosts = [
        local.fqdn_jitsi_keycloak
      ]
    }
  }
}
