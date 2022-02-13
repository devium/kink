locals {
  keycloak_namespace = "keycloak"
  keycloak_domain = "${var.subdomains.keycloak}.${var.domain}"
}

resource "helm_release" "keycloak" {
  name = var.release_name
  namespace = local.keycloak_namespace
  create_namespace = true

  repository = "https://codecentric.github.io/helm-charts"
  chart = "keycloak"
  version = var.versions.keycloak_helm

  values = [ <<-YAML
    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt
      rules:
        - host: ${local.keycloak_domain}
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: cert-secret
          hosts:
            - ${local.keycloak_domain}

    postgresql:
      enabled: false

    extraEnv: |
      - name: DB_VENDOR
        value: postgres
      - name: DB_ADDR
        value: ${var.release_name}-postgresql.postgres.svc.cluster.local

    extraEnvFrom: |
      - secretRef:
          name: '{{ include "keycloak.fullname" . }}-db'

    secrets:
      db:
        stringData:
          DB_PASSWORD: ${var.db_passwords.keycloak}
    YAML
  ]
}
