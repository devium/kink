locals {
  fqdn       = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
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
  timeout    = 120

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

        m.identity_server:
          base_url: ""

        org.matrix.msc3575.proxy:
          url: https://${var.cluster_vars.domains.sliding_sync}

        im.vector.riot.jitsi:
          preferredDomain: ${var.cluster_vars.domains.jitsi}

        org.matrix.msc2965.authentication:
          issuer: https://${var.cluster_vars.domains.domain}/
          account: https://${var.cluster_vars.domains.mas}/account

        io.element.e2ee:
          secure_backup_required: true
          secure_backup_setup_methods:
          - key

    config:
      enableRegistration: false
      registrationSharedSecret: ${var.config.secrets.registration}
      macaroonSecretKey: ${var.config.secrets.macaroon}

    extraConfig:
      admin_contact: ${var.config.admin_contact}
      allow_public_rooms_over_federation: true
      autocreate_auto_join_rooms: false
      default_room_version: "11"
      enable_set_displayname: false
      max_upload_size: ${local.max_upload}
      web_client_location: https://${var.cluster_vars.domains.element}
      allow_guest_access: true

      auto_join_rooms:
        ${indent(4, yamlencode([for room in var.config.default_rooms : "#${room}:${var.cluster_vars.domains.domain}"]))}

      password_config:
        enabled: false

      email:
        smtp_host: ${var.cluster_vars.mail_server}
        smtp_port: 587
        smtp_user: ${var.config.mail.account}@${var.cluster_vars.domains.domain}
        smtp_pass: ${var.config.mail.password}
        force_tls: true
        enable_notifs: true
        notif_from: "%(app)s"

      experimental_features:
        msc3861:
          enabled: true
          # Trailing slash is important for URL matching with the MAS.
          issuer: https://${var.cluster_vars.domains.domain}/
          client_id: ${var.config.mas_client}
          client_auth_method: client_secret_basic
          client_secret: ${var.config.secrets.mas_client}
          admin_token: ${var.config.secrets.admin_token}
          account_management_url: https://${var.cluster_vars.domains.mas}/account

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
        nginx.ingress.kubernetes.io/use-regex: "true"

      # Path type "Prefix" does not match when regex paths are defined on the same host.
      paths:
        - path: /(_matrix/*|_synapse/*)
          pathType: ImplementationSpecific
          backend:
            service:
              name: ${var.cluster_vars.release_name}-matrix-synapse
              port:
                number: 8008

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
