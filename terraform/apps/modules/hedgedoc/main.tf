locals {
  fqdn     = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
  oidc_url = "https://${var.cluster_vars.domains.keycloak}/realms/${var.cluster_vars.keycloak_realm}/protocol/openid-connect"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-inline'"    
    "frame-src"       = "*"
    "frame-ancestors" = "'self' https://${var.cluster_vars.domains.keycloak}"
  })
}

resource "helm_release" "hedgedoc" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://nicholaswilde.github.io/helm-charts/"
  chart      = "hedgedoc"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    secret:
      CMD_DB_URL: postgres://${var.config.db.username}:${var.config.db.password}@${var.cluster_vars.db_host}:5432/${var.config.db.database}
      CMD_SESSION_SECRET: ${var.config.secret}
      CMD_OAUTH2_CLIENT_SECRET: ${var.config.keycloak.secret}

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
      CMD_OAUTH2_CLIENT_ID: ${var.config.keycloak.client}
      CMD_OAUTH2_PROVIDERNAME: ${var.config.keycloak.name}
      CMD_OAUTH2_SCOPE: openid email private_profile
      CMD_EMAIL: "false"
      CMD_ALLOW_EMAIL_REGISTER: "false"
      CMD_ALLOW_ANONYMOUS: "false"
      CMD_ALLOW_ANONYMOUS_EDITS: "true"
      CMD_ALLOW_FREEURL: "true"

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
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

    persistence:
      config:
        enabled: true
        existingClaim: hedgedoc-pvc

    resources:
      requests:
        memory: ${var.config.memory}

    strategy:
      type: Recreate
  YAML
  ]
}
