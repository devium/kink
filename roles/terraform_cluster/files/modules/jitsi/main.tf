locals {
  fqdn                 = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
  keycloak_adapter_url = "https://raw.githubusercontent.com/nordeck/jitsi-keycloak-adapter/${var.config.version_keycloak_adapter}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-inline' 'unsafe-eval' https://www.youtube.com"
    "connect-src"     = "'self' https://${var.cluster_vars.domains.keycloak} wss: https://www.gravatar.com"
    "worker-src"      = "'self' blob:"
    "frame-src"       = "https://www.youtube.com"
    "frame-ancestors" = "https://${var.cluster_vars.domains.element}"
  })
  csp_jitsi_keycloak = merge(var.cluster_vars, {
    "style-src"       = "'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net"
    "frame-ancestors" = "https://${var.cluster_vars.domains.element}"
  })
}

resource "kubernetes_config_map_v1" "prosody_plugins" {
  metadata {
    name      = "prosody-plguins"
    namespace = var.config.namespace
  }

  data = {
    "mod_muc_rooms.lua" = <<-LUA
      ${file("${path.module}/mod_muc_rooms.lua")}
    LUA
  }
}

data "http" "web_keycloak_body_html" {
  url = "${local.keycloak_adapter_url}/templates/usr/share/jitsi-meet/body.html"
}

data "http" "web_keycloak_oidc_adapter_html" {
  url = "${local.keycloak_adapter_url}/templates/usr/share/jitsi-meet/static/oidc-adapter.html"
}

data "http" "web_keycloak_oidc_redirect_html" {
  url = "${local.keycloak_adapter_url}/templates/usr/share/jitsi-meet/static/oidc-redirect.html"
}

data "http" "web_keycloak_meet_conf" {
  url = "${local.keycloak_adapter_url}/templates/jitsi-web-container/defaults/meet.conf"
}

resource "kubernetes_config_map_v1" "web_config" {
  metadata {
    name      = "web-config"
    namespace = var.config.namespace
  }

  data = {
    "20-config-manual" = <<-BASH
      #!/usr/bin/env bash
      cat <<JS>>/config/config.js
      config.toolbarConfig = {
        autoHideWhileChatIsOpen: true
      };
      config.desktopSharingFrameRate = {
        min: 30,
        max: 30
      };
      JS
    BASH

    "body.html" = <<-HTML
      ${data.http.web_keycloak_body_html.response_body}
    HTML

    "oidc-adapter.html" = <<-HTML
      ${data.http.web_keycloak_oidc_adapter_html.response_body}
    HTML

    "oidc-redirect.html" = <<-HTML
      ${data.http.web_keycloak_oidc_redirect_html.response_body}
    HTML

    "meet.conf" = <<-CONF
      ${data.http.web_keycloak_meet_conf.response_body}
    CONF
  }
}

resource "helm_release" "jitsi" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://jitsi-contrib.github.io/jitsi-helm/"
  chart      = "jitsi-meet"
  version    = var.config.version_helm

  values = [<<-YAML
    publicURL: https://${local.fqdn}
    enableAuth: true

    web:
      image:
        tag: ${var.config.version}

      ingress:
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
          nginx.ingress.kubernetes.io/enable-cors: "true"
          # TODO: This wildcard does not actually work. Instead it defaults to *. Should be fixed in a newer Ingress version.
          nginx.ingress.kubernetes.io/cors-allow-origin: https://*.${var.cluster_vars.domains.domain}
          nginx.ingress.kubernetes.io/configuration-snippet: |
            more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

        enabled: true

        hosts:
          - host: ${local.fqdn}
            paths:
              - /

        tls:
          - secretName: ${local.fqdn}-tls
            hosts:
              - ${local.fqdn}

      resolverIP: rke2-coredns-rke2-coredns.kube-system.svc.cluster.local

      extraVolumeMounts:
        - name: web-config
          mountPath: /etc/cont-init.d/20-config-manual
          subPath: 20-config-manual
        - name: web-config
          mountPath: /usr/share/jitsi-meet/body.html
          subPath: body.html
        - name: web-config
          mountPath: /usr/share/jitsi-meet/static/oidc-adapter.html
          subPath: oidc-adapter.html
        - name: web-config
          mountPath: /usr/share/jitsi-meet/static/oidc-redirect.html
          subPath: oidc-redirect.html
        - name: web-config
          mountPath: /defaults/meet.conf
          subPath: meet.conf

      extraVolumes:
        - name: web-config
          configMap:
            name: ${one(kubernetes_config_map_v1.web_config.metadata).name}
            defaultMode: 0777

      extraEnvs:
        ADAPTER_INTERNAL_URL: "http://jitsi-keycloak"
        ENABLE_P2P: "false"

      resources:
        requests:
          memory: ${var.config.memory_web}

    jvb:
      image:
        tag: ${var.config.version}

      service:
        enabled: true
        # Nginx UDP ingress didn't seem to work, so back to good old direct NodePort.
        type: NodePort

      UDPPort: 30000
      nodePort: 30000
      useNodeIP: true

      xmpp:
        password: ${var.config.secrets.jvb}

      metrics:
        enabled: true

        image:
          tag: ${var.config.version_prometheus_exporter}

      resources:
        requests:
          memory: ${var.config.memory_jvb}

      readinessProbe:
        httpGet:
          path: /about/health
          port: 8080

        initialDelaySeconds: 45

      livenessProbe:
        httpGet:
          path: /about/health
          port: 8080

        initialDelaySeconds: 45

    jicofo:
      image:
        tag: ${var.config.version}

      xmpp:
        password: ${var.config.secrets.jicofo}

      resources:
        requests:
          memory: ${var.config.memory_jicofo}

      extraEnvs:
        JICOFO_AUTH_TYPE: internal
        JICOFO_AUTH_LIFETIME: 100 milliseconds

    prosody:
      image:
        tag: ${var.config.version}

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
          value: ${var.config.secrets.jwt}
        - name: JWT_ALLOW_EMPTY
          value: "true"
        - name: ENABLE_END_CONFERENCE
          value: "false"

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
          cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}

        enabled: true

        hosts:
          - host: ${local.fqdn}
            paths:
              - /rooms

        tls:
          - secretName: ${local.fqdn}-tls
            hosts:
              - ${local.fqdn}

      resources:
        requests:
          memory: ${var.config.memory_prosody}

    websockets:
      colibri:
        enabled: true

      xmpp:
        enabled: true
  YAML
  ]
}

resource "kubernetes_deployment_v1" "jitsi_keycloak" {
  metadata {
    name      = "jitsi-keycloak"
    namespace = var.config.namespace

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
          image = "ghcr.io/nordeck/jitsi-keycloak-adapter:${var.config.version_keycloak_adapter}"
          name  = "jitsi-keycloak"

          port {
            container_port = 9000
          }

          env {
            name  = "KEYCLOAK_ORIGIN"
            value = "https://${var.cluster_vars.domains.keycloak}"
          }
          env {
            name  = "KEYCLOAK_REALM"
            value = var.cluster_vars.keycloak_realm
          }
          env {
            name  = "KEYCLOAK_CLIENT_ID"
            value = var.config.keycloak.client
          }
          env {
            name  = "JWT_APP_ID"
            value = "jitsi"
          }
          env {
            name  = "JWT_APP_SECRET"
            value = var.config.secrets.jwt
          }
          env {
            name  = "ALLOW_UNSECURE_CERT"
            value = "true"
          }

          resources {
            requests = {
              memory = var.config.memory_keycloak_adapter
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "jitsi_keycloak" {
  metadata {
    name      = "jitsi-keycloak"
    namespace = var.config.namespace
  }

  spec {
    selector = {
      app = one(kubernetes_deployment_v1.jitsi_keycloak.metadata).labels.app
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 9000
    }
  }
}
