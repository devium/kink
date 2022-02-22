locals {
  hedgedoc_namespace = "hedgedoc"
}

resource "helm_release" "hedgedoc" {
  name             = var.release_name
  namespace        = local.hedgedoc_namespace
  create_namespace = true

  repository = "https://nicholaswilde.github.io/helm-charts/"
  chart      = "hedgedoc"
  version    = var.versions.hedgedoc_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.hedgedoc}

    secret:
      CMD_DB_URL: postgres://hedgedoc:${var.db_passwords.hedgedoc}@${var.release_name}-postgresql.postgres.svc.cluster.local:5432/hedgedoc
      CMD_SESSION_SECRET: ${var.hedgedoc_secret}
      CMD_OAUTH2_CLIENT_SECRET: ${var.keycloak_secrets.hedgedoc}

    env:
      CMD_PROTOCOL_USESSL: "true"
      CMD_DOMAIN: ${var.subdomains.hedgedoc}.${var.domain}
      CMD_OAUTH2_USER_PROFILE_URL: https://${var.subdomains.keycloak}.${var.domain}/auth/realms/${var.keycloak_realm}/protocol/openid-connect/userinfo
      CMD_OAUTH2_USER_PROFILE_USERNAME_ATTR: preferred_username
      CMD_OAUTH2_USER_PROFILE_ID_ATTR: id
      CMD_OAUTH2_USER_PROFILE_DISPLAY_NAME_ATTR: preffered_username
      CMD_OAUTH2_USER_PROFILE_EMAIL_ATTR: email
      CMD_OAUTH2_TOKEN_URL: https://${var.subdomains.keycloak}.${var.domain}/auth/realms/${var.keycloak_realm}/protocol/openid-connect/token
      CMD_OAUTH2_AUTHORIZATION_URL: https://${var.subdomains.keycloak}.${var.domain}/auth/realms/${var.keycloak_realm}/protocol/openid-connect/auth
      CMD_OAUTH2_CLIENT_ID: hedgedoc
      CMD_OAUTH2_PROVIDERNAME: Keycloak
      CMD_EMAIL: "false"
      CMD_ALLOW_EMAIL_REGISTER: "false"
      CMD_ALLOW_ANONYMOUS: "false"
      CMD_ALLOW_ANONYMOUS_EDITS: "true"
      CMD_ALLOW_FREEURL: "true"

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt
      hosts:
        - host: ${var.subdomains.hedgedoc}.${var.domain}
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: cert-secret
          hosts:
            - ${var.subdomains.hedgedoc}.${var.domain}
    YAML
  ]
}
