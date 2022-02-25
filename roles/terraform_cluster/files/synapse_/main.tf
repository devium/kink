locals {
  namespace   = "synapse"
  oidc_issuer = "https://${var.subdomains.keycloak}.${var.domain}/auth/realms/${var.keycloak_realm}"
}

resource "helm_release" "synapse" {
  name             = var.release_name
  namespace        = local.namespace
  create_namespace = true

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

    database:
      host: ${var.release_name}-postgresql.postgres.svc.cluster.local
      mode: postgresql
      name: synapse
      password: ${var.db_passwords.synapse}
      port: 5432
      username: synapse

    homeserver:
      server_name: ${var.subdomains.synapse}.${var.domain}
      report_stats: false
      send_federation: true

      signing_key_path: "/data/${var.domain}.signing.key"
      database:
        name: psycopg2
        args:
          user: synapse
          password: ${var.db_passwords.synapse}
          database: synapse
          host: ${var.release_name}-postgresql.postgres.svc.cluster.local
          port: 5432

      oidc_providers:
        - idp_id: keycloak
          idp_name: Keycloak
          issuer: ${local.oidc_issuer}
          client_id: matrix
          client_secret: ${var.keycloak_secrets.synapse}
          scopes: ["openid", "profile"]
          authorization_endpoint: ${local.oidc_issuer}/protocol/openid-connect/auth
          token_endpoint: ${local.oidc_issuer}/protocol/openid-connect/token
          userinfo_endpoint: ${local.oidc_issuer}/protocol/openid-connect/userinfo
          user_mapping_provider:
            config:
              localpart_template: "{% raw %}{{ user.sub.split('-')[0] }}{% endraw %}"
              display_name_template: "{% raw %}{{ user.preferred_username }}{% endraw %}"
              email_template: "{% raw %}{{ user.email }}{% endraw %}"

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt
      hosts:
        - host: ${var.subdomains.synapse}.${var.domain}
          paths:
            - /
      tls:
        - secretName: cert-secret
          hosts:
            - ${var.subdomains.synapse}.${var.domain}

    YAML
  ]
}
