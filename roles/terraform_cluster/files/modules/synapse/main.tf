locals {
  fqdn              = "${var.subdomains.synapse}.${var.domain}"
  fqdn_sliding_sync = "${var.subdomains.sliding_sync}.${var.domain}"
  oidc_url          = "https://${var.subdomains.keycloak}.${var.domain}/realms/${var.keycloak_realm}"
  max_upload        = "20M"
}

resource "helm_release" "synapse" {
  name      = var.release_name
  namespace = var.namespaces.synapse

  repository = "https://ananace.gitlab.io/charts"
  chart      = "matrix-synapse"
  version    = var.versions.synapse_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.synapse}

    serverName: ${var.domain}
    publicServerName: ${local.fqdn}

    wellknown:
      enabled: true

      client:
        m.homeserver:
          base_url: https://${local.fqdn}

        org.matrix.msc3575.proxy:
          url: https://${local.fqdn_sliding_sync}

        im.vector.riot.jitsi:
          preferredDomain: ${var.subdomains.jitsi}.${var.domain}

    config:
      enableRegistration: false
      registrationSharedSecret: ${var.synapse_secrets.registration}
      macaroonSecretKey: ${var.synapse_secrets.macaroon}

    extraConfig:
      default_room_version: "9"
      web_client_location: https://${var.subdomains.element}.${var.domain}
      autocreate_auto_join_rooms: false
      max_upload_size: ${local.max_upload}
      auto_join_rooms:
        - "#lobby:${var.domain}"

      password_config:
        enabled: false

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

    synapse:
      podSecurityContext:
        fsGroup: 666
        runAsGroup: 666
        runAsUser: 666
        fsGroupChangePolicy: "OnRootMismatch"

      resources:
        requests:
          memory: ${var.resources.memory.synapse}

      strategy:
        type: Recreate


    postgresql:
      enabled: false

    externalPostgresql:
      host: ${var.db_host}
      port: 5432
      database: synapse
      username: synapse
      password: ${var.db_passwords.synapse}

    persistence:
      enabled: true
      existingClaim: ${var.pvcs.synapse}

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/proxy-body-size: ${local.max_upload}

      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}
        - secretName: ${var.domain}-tls
          hosts:
            - ${var.domain}
  YAML
  ]
}

resource "helm_release" "sliding_sync" {
  name      = "${var.release_name}-sliding-sync"
  namespace = var.namespaces.synapse

  repository = "https://ananace.gitlab.io/charts"
  chart      = "sliding-sync-proxy"
  version    = var.versions.sliding_sync_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.sliding_sync}

    matrixServer: https://${var.domain}

    resources:
      requests:
        memory: ${var.resources.memory.sliding_sync}

    ingress:
      enabled: true
      serveSimpleClient: true

      hosts:
        - ${local.fqdn_sliding_sync}

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"

      tls:
        - secretName: ${local.fqdn_sliding_sync}-tls
          hosts:
            - ${local.fqdn_sliding_sync}

    postgresql:
      enabled: false

    externalPostgresql:
      host: ${var.db_host}
      sslmode: disable
      database: sliding_sync
      username: sliding_sync
      password: ${var.db_passwords.sliding_sync}
  YAML
  ]
}
