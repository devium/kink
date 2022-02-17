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
      - name: KEYCLOAK_USER
        value: admin
      - name: PROXY_ADDRESS_FORWARDING
        value: "true"

    extraEnvFrom: |
      - secretRef:
          name: '{{ include "keycloak.fullname" . }}-db'
      - secretRef:
          name: '{{ include "keycloak.fullname" . }}-admin-password'

    secrets:
      db:
        stringData:
          DB_PASSWORD: ${var.db_passwords.keycloak}
      admin-password:
        stringData:
          KEYCLOAK_PASSWORD: ${var.keycloak_admin_password}

    extraVolumeMounts: |
      - name: theme
        mountPath: /opt/jboss/keycloak/themes/custom

    extraVolumes: |
      - name: theme
        emptyDir: {}

    extraInitContainers: |
      - name: keycloak-theme
        image: ghcr.io/devium/kink-keycloak-theme
        imagePullPolicy: Always
        command:
          - sh
        args:
          - -c
          - |
            echo "Copyting theme..."
            cp -R /custom/* /theme
        volumeMounts:
          - name: theme
            mountPath: /theme
    YAML
  ]
}
