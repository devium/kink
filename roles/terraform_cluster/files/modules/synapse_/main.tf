locals {
  fqdn     = "${var.subdomains.synapse}.${var.domain}"
  oidc_url = "https://${var.subdomains.keycloak}.${var.domain}/auth/realms/${var.keycloak_realm}"
}

resource "kubernetes_config_map_v1" "nginx_data" {
  metadata {
    name      = "nginx-data"
    namespace = var.namespaces.synapse
  }

  data = {
    server = "{\"m.server\": \"https://${var.subdomains.synapse}.${var.domain}\"}"
    client = "{\"m.homeserver\": {\"base_url\": \"https://${var.subdomains.synapse}.${var.domain}/\"}}"
  }
}

resource "helm_release" "nginx" {
  name       = "${var.release_name}-nginx"
  namespace  = var.namespaces.synapse
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = var.versions.nginx_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.nginx}

    service:
      type: ClusterIP

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/cors-allow-origin: "*"

      hostname: ${var.domain}
      path: /.well-known/matrix/
      pathType: Prefix
      tls: yes

    staticSiteConfigmap: ${one(kubernetes_config_map_v1.nginx_data.metadata).name}

    serverBlock: |
      server {
        listen 8080;
        location /.well-known/matrix/ {
          alias /app/;
        }
      }
  YAML
  ]
}

resource "helm_release" "synapse" {
  name      = var.release_name
  namespace = var.namespaces.synapse

  repository = "https://halkeye.github.io/helm-charts/"
  chart      = "synapse"
  version    = var.versions.synapse_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.synapse}

    replicaCounts:
      master: 1
      federation_reader: 0
      federation_sender: 0

    settings:
      report_stats: "no"

    database:
      host: ${var.db_host}
      mode: postgresql
      name: synapse
      password: ${var.db_passwords.synapse}
      port: 5432
      username: synapse

    existingMediaClaim: ${var.pvcs.synapse}

    podSecurityContext:
      fsGroup: 991
      fsGroupChangePolicy: "OnRootMismatch"

    homeserver:
      server_name: ${var.domain}
      public_baseurl: https://${local.fqdn}

      default_room_version: "9"
      media_store_path: /media
      report_stats: false
      send_federation: true
      signing_key_path: "/data/${var.domain}.signing.key"
      web_client_location: https://${local.fqdn}

      database:
        name: psycopg2

        args:
          user: synapse
          password: ${var.db_passwords.synapse}
          database: synapse
          host: ${var.db_host}
          port: 5432

      oidc_providers:
        - idp_id: keycloak
          idp_name: Keycloak
          issuer: ${local.oidc_url}
          client_id: ${var.keycloak_clients.synapse}
          client_secret: ${var.keycloak_secrets.synapse}
          scopes: ["openid", "private_profile"]
          authorization_endpoint: ${local.oidc_url}/protocol/openid-connect/auth
          token_endpoint: ${local.oidc_url}/protocol/openid-connect/token
          userinfo_endpoint: ${local.oidc_url}/protocol/openid-connect/userinfo

          user_mapping_provider:
            config:
              localpart_template: "{{ user.sub.split('-')[0] }}"
              display_name_template: "{{ user.preferred_username }}"

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/cors-allow-origin: "*"

      hosts:
        - host: ${local.fqdn}
          paths:
            - /

      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}
  YAML
  ]
}
