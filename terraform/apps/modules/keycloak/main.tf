locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src"      = "'self' 'unsafe-inline' 'unsafe-eval'"
    "frame-src"       = "'self' https://${var.cluster_vars.domains.grafana} https://${var.cluster_vars.domains.hedgedoc} https://${var.cluster_vars.domains.wiki}"
  })
}

resource "helm_release" "keycloak" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloakx"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
        nginx.ingress.kubernetes.io/proxy-buffer-size: "128k"
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

      rules:
        - host: ${local.fqdn}
          paths:
            - path: /
              pathType: Prefix

      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    resources:
      requests:
        memory: ${var.config.memory}

    command:
      - "/opt/keycloak/bin/kc.sh"
      - "start"
      - "--http-enabled=true"
      - "--http-port=8080"
      - "--hostname=https://${local.fqdn}"
      - "--features=account3"

    postgresql:
      enabled: false

    extraEnv: |
      - name: KEYCLOAK_ADMIN
        value: admin
      - name: JAVA_OPTS_APPEND
        value: >-
          -Djgroups.dns.query={{ include "keycloak.fullname" . }}-headless

    extraEnvFrom: |
      - secretRef:
          name: '{{ include "keycloak.fullname" . }}-admin-password'

    secrets:
      admin-password:
        stringData:
          KEYCLOAK_ADMIN_PASSWORD: ${var.config.admin_password}

    http:
      relativePath: "/"

    database:
      vendor: postgres
      hostname: ${var.cluster_vars.db_host}
      port: 5432
      database: ${var.config.db.database}
      username: ${var.config.db.username}
      password: ${var.config.db.password}
  YAML
  ]
}
