locals {
  fqdn     = "${var.subdomains.hedgedoc}.${var.domain}"
  oidc_url = "https://${var.subdomains.keycloak}.${var.domain}/auth/realms/${var.keycloak_realm}/protocol/openid-connect/"
}

resource "helm_release" "hedgedoc" {
  name       = var.release_name
  namespace  = var.namespaces.hedgedoc
  repository = "https://nicholaswilde.github.io/helm-charts/"
  chart      = "hedgedoc"
  version    = var.versions.hedgedoc_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.hedgedoc}

    secret:
      CMD_DB_URL: postgres://hedgedoc:${var.db_passwords.hedgedoc}@${var.db_host}:5432/hedgedoc
      CMD_SESSION_SECRET: ${var.hedgedoc_secret}
      CMD_OAUTH2_CLIENT_SECRET: ${var.keycloak_secrets.hedgedoc}

    env:
      CMD_PROTOCOL_USESSL: "true"
      CMD_DOMAIN: ${local.fqdn}
      CMD_OAUTH2_USER_PROFILE_URL: ${local.oidc_url}/userinfo
      CMD_OAUTH2_USER_PROFILE_USERNAME_ATTR: preferred_username
      CMD_OAUTH2_USER_PROFILE_ID_ATTR: id
      CMD_OAUTH2_USER_PROFILE_DISPLAY_NAME_ATTR: preferred_username
      CMD_OAUTH2_USER_PROFILE_EMAIL_ATTR: email
      CMD_OAUTH2_TOKEN_URL: ${local.oidc_url}/token
      CMD_OAUTH2_AUTHORIZATION_URL: ${local.oidc_url}/auth
      CMD_OAUTH2_CLIENT_ID: ${var.keycloak_clients.hedgedoc}
      CMD_OAUTH2_PROVIDERNAME: Keycloak
      CMD_EMAIL: "false"
      CMD_ALLOW_EMAIL_REGISTER: "false"
      CMD_ALLOW_ANONYMOUS: "false"
      CMD_ALLOW_ANONYMOUS_EDITS: "true"
      CMD_ALLOW_FREEURL: "true"

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}

      hosts:
        - host: ${local.fqdn}
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    YAML
  ]
}
