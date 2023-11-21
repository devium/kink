locals {
  fqdn       = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
  oidc_url   = "https://${var.cluster_vars.domains.keycloak}/realms/${var.cluster_vars.keycloak_realm}"
  max_upload = "20M"
}

resource "kubernetes_secret_v1" "signing_key" {
  metadata {
    name      = "signing-key"
    namespace = var.config.namespace
  }

  data = {
    "signing.key" = var.config.secrets.signing_key
  }
}

resource "helm_release" "synapse" {
  name      = var.cluster_vars.release_name
  namespace = var.config.namespace

  repository = "https://ananace.gitlab.io/charts"
  chart      = "matrix-synapse"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    serverName: ${var.cluster_vars.domains.domain}
    publicServerName: ${local.fqdn}

    wellknown:
      enabled: true

      client:
        m.homeserver:
          base_url: https://${local.fqdn}

        org.matrix.msc3575.proxy:
          url: https://${var.cluster_vars.domains.sliding_sync}

        im.vector.riot.jitsi:
          preferredDomain: ${var.cluster_vars.domains.jitsi}

        org.matrix.msc2965.authentication:
          issuer: ${local.oidc_url}
          account: ${local.oidc_url}/account

    config:
      enableRegistration: false
      registrationSharedSecret: ${var.config.secrets.registration}
      macaroonSecretKey: ${var.config.secrets.macaroon}

    extraConfig:
      default_room_version: "9"
      web_client_location: https://${var.cluster_vars.domains.element}
      autocreate_auto_join_rooms: false
      max_upload_size: ${local.max_upload}
      auto_join_rooms:
        - "#lobby:${var.cluster_vars.domains.domain}"

      password_config:
        enabled: false

      oidc_providers:
        - idp_id: keycloak
          idp_name: Keycloak
          issuer: ${local.oidc_url}
          client_id: ${var.config.keycloak.client}
          client_secret: ${var.config.keycloak.secret}
          scopes: ["openid", "private_profile"]
          authorization_endpoint: ${local.oidc_url}/protocol/openid-connect/auth
          token_endpoint: ${local.oidc_url}/protocol/openid-connect/token
          userinfo_endpoint: ${local.oidc_url}/protocol/openid-connect/userinfo
          backchannel_logout_enabled: true

          user_mapping_provider:
            config:
              localpart_template: "{{ user.sub.split('-')[0] }}"
              display_name_template: "{{ user.preferred_username }}"

    signingkey:
      existingSecret: signing-key
      existingSecretKey: signing.key

      job:
        enabled: false

    synapse:
      podSecurityContext:
        fsGroup: 666
        runAsGroup: 666
        runAsUser: 666
        fsGroupChangePolicy: "OnRootMismatch"

      resources:
        requests:
          memory: ${var.config.memory}

      strategy:
        type: Recreate

    postgresql:
      enabled: false

    externalPostgresql:
      host: ${var.cluster_vars.db_host}
      port: 5432
      database: ${var.config.db.database}
      username: ${var.config.db.username}
      password: ${var.config.db.password}

    persistence:
      enabled: true
      existingClaim: synapse-pvc

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/proxy-body-size: ${local.max_upload}

      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}
        - secretName: ${var.cluster_vars.domains.domain}-tls
          hosts:
            - ${var.cluster_vars.domains.domain}
  YAML
  ]
}
