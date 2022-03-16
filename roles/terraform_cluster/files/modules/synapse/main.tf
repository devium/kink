locals {
  fqdn     = "${var.subdomains.synapse}.${var.domain}"
  oidc_url = "https://${var.subdomains.keycloak}.${var.domain}/auth/realms/${var.keycloak_realm}"
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

        im.vector.riot.jitsi:
          preferredDomain: ${var.subdomains.jitsi}.${var.domain}

    config:
      registrationSharedSecret: ${var.synapse_secrets.registration}
      macaroonSecretKey: ${var.synapse_secrets.macaroon}

    extraConfig:
      default_room_version: "9"
      web_client_location: https://${var.subdomains.element}.${var.domain}
      autocreate_auto_join_rooms: false
      auto_join_rooms:
        - "#lobby:${var.domain}"

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
