locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-inline'"
    "frame-src"       = "'self' https://${var.cluster_vars.domains.collabora}"
    "frame-ancestors" = "https:"
  })
}

resource "helm_release" "nextcloud" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://nextcloud.github.io/helm/"
  chart      = "nextcloud"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/proxy-body-size: 500m
        nginx.ingress.kubernetes.io/cors-allow-headers: "X-Forwarded-For"

        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

      hosts:
        - host: ${local.fqdn}
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    phpClientHttpsFix:
      enabled: false
      protocol: https

    resources:
      requests:
        memory: ${var.config.memory}

    nextcloud:
      host: ${local.fqdn}
      username: admin_temp
      password: ${var.config.admin_password}

      configs:
        custom.config.php: |-
          <?php
          $CONFIG = array (
            'maintenance_window_start' => 1,
            'default_phone_region' => 'DE',
            'default_timezone' => 'Europe/Berlin'
          );

        proxy.config.php: |-
          <?php
          $CONFIG = array (
            'trusted_proxies' => array(
              0 => '127.0.0.1',
              1 => '10.0.0.0/8',
            ),
            'forwarded_for_headers' => array('HTTP_X_FORWARDED_FOR'),
          );

      extraEnv:
        # Env values with NC_ prefix override config values, just in case they become outdated
        - name: NC_dbhost
          value: ${var.cluster_vars.db_host}
        - name: NC_dbport
          value: "5432"
        - name: NC_dbname
          value: nextcloud
        - name: NC_dbuser
          valueFrom:
            secretKeyRef:
              name: ${var.cluster_vars.release_name}-db
              key: db-username
        - name: NC_dbpassword
          valueFrom:
            secretKeyRef:
              name: ${var.cluster_vars.release_name}-db
              key: db-password

    internalDatabase:
      enabled: false

    externalDatabase:
      enabled: true
      type: postgresql
      host: ${var.cluster_vars.db_host}
      user: ${var.config.db.username}
      password: ${var.config.db.password}
      database: ${var.config.db.database}

    persistence:
      enabled: true
      existingClaim: nextcloud-pvc

    cronjob:
      enabled: true

    redis:
      enabled: true
      auth:
        enabled: false

      master:
        persistence:
          enabled: false

      replica:
        persistence:
          enabled: false
  YAML
  ]
}

resource "kubernetes_ingress_v1" "calendar_cache" {
  metadata {
    name      = "nextcloud-calendar"
    namespace = var.config.namespace

    annotations = {
      "cert-manager.io/cluster-issuer"                 = var.cluster_vars.issuer
      "nginx.ingress.kubernetes.io/enable-cors"        = "true"
      "nginx.ingress.kubernetes.io/proxy-buffering"    = "on"

      "nginx.ingress.kubernetes.io/configuration-snippet" = <<-CONF
        more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

        proxy_ignore_headers Cache-Control;
        proxy_hide_header Cache-Control;
        proxy_ignore_headers Set-Cookie;
        proxy_hide_header Set-Cookie;
        proxy_ignore_headers Expires;
        proxy_hide_header Expires;

        proxy_cache app-cache;
        proxy_cache_valid 200 30m;
        proxy_cache_background_update on;
        proxy_cache_use_stale updating;
        more_set_headers "X-Cache-Status: $upstream_cache_status";
      CONF
    }
  }

  spec {
    rule {
      host = local.fqdn

      http {
        path {
          path      = "/remote.php/dav/public-calendars/"
          path_type = "Prefix"

          backend {
            service {
              name = "${var.cluster_vars.release_name}-nextcloud"

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
  }
}
