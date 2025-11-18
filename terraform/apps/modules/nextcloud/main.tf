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
        nginx.ingress.kubernetes.io/proxy-body-size: "500m"
        # Regex used in calendar caching location.
        nginx.ingress.kubernetes.io/use-regex: "true"

        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

        # Service discovery block as recommended in the Helm chart's README.md:
        nginx.ingress.kubernetes.io/server-snippet: |-
          server_tokens off;
          proxy_hide_header X-Powered-By;
          rewrite ^/.well-known/webfinger /index.php/.well-known/webfinger last;
          rewrite ^/.well-known/nodeinfo /index.php/.well-known/nodeinfo last;
          rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
          rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json;
          location = /.well-known/carddav {
            return 301 $scheme://$host/remote.php/dav;
          }
          location = /.well-known/caldav {
            return 301 $scheme://$host/remote.php/dav;
          }
          location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
          }
          location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
            deny all;
          }
          location ~ ^/(?:autotest|occ|issue|indie|db_|console) {
            deny all;
          }
          # End of service discovery block.
          # Calendar caching
          location ~ ^/remote\.php/dav/public-calendars/.+ {
            # Enable CORS for calendar requests.
            add_header 'Access-Control-Allow-Origin' '*' always;

            # NGINX does not cache responses that set cookies, so just remove them.
            proxy_ignore_headers Set-Cookie;
            proxy_hide_header Set-Cookie;

            proxy_cache app-cache;
            proxy_cache_valid 200 10m;
            proxy_cache_background_update on;
            proxy_cache_use_stale updating;
            more_set_headers "X-Cache-Status: $upstream_cache_status";

            proxy_pass http://${var.cluster_vars.release_name}-nextcloud.nextcloud.svc.cluster.local:8080$uri$is_args$args;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          }

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
            'default_timezone' => 'Europe/Berlin',
            'overwrite.cli.url' => 'https://${local.fqdn}'
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

# resource "kubernetes_ingress_v1" "calendar_cache" {
#   metadata {
#     name      = "nextcloud-calendar"
#     namespace = var.config.namespace

#     annotations = {
#       "cert-manager.io/cluster-issuer"                 = var.cluster_vars.issuer

#       "nginx.ingress.kubernetes.io/configuration-snippet" = <<-CONF
#         more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

#         proxy_ignore_headers Cache-Control;
#         proxy_hide_header Cache-Control;
#         proxy_ignore_headers Set-Cookie;
#         proxy_hide_header Set-Cookie;
#         proxy_ignore_headers Expires;
#         proxy_hide_header Expires;

#         proxy_cache app-cache;
#         proxy_cache_valid 200 30m;
#         proxy_cache_background_update on;
#         proxy_cache_use_stale updating;
#         more_set_headers "X-Cache-Status: $upstream_cache_status";
#       CONF
#     }
#   }

#   spec {
#     rule {
#       host = local.fqdn

#       http {
#         path {
#           path      = "/remote\\.php/dav/public-calendars/.+"
#           path_type = "ImplementationSpecific"

#           backend {
#             service {
#               name = "${var.cluster_vars.release_name}-nextcloud"

#               port {
#                 number = 8080
#               }
#             }
#           }
#         }
#       }
#     }

#     tls {
#       secret_name = "${local.fqdn}-tls"

#       hosts = [
#         local.fqdn
#       ]
#     }
#   }
# }
