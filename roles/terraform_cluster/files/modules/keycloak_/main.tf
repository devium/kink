locals {
  fqdn = "${var.subdomains.keycloak}.${var.domain}"
}

resource "helm_release" "keycloak" {
  name       = var.release_name
  namespace  = var.namespaces.keycloak
  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloak"
  version    = var.versions.keycloak_helm

  values = [<<-YAML
    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/proxy-buffer-size: "128k"

      rules:
        - host: ${local.fqdn}
          paths:
            - path: /
              pathType: Prefix

      tls:
        - secretName: ${local.fqdn}-tls
          hosts:
            - ${local.fqdn}

    postgresql:
      enabled: false

    extraEnv: |
      - name: DB_VENDOR
        value: postgres
      - name: DB_ADDR
        value: ${var.db_host}
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
          KEYCLOAK_PASSWORD: ${var.admin_passwords.keycloak}

    extraVolumeMounts: |
      - name: theme
        mountPath: /opt/jboss/keycloak/themes/custom

    extraVolumes: |
      - name: theme
        emptyDir: {}

    extraInitContainers: |
      - name: keycloak-theme
        image: ghcr.io/devium/kink-keycloak-theme:${var.versions.keycloak_theme}
        imagePullPolicy: Always

        command:
          - sh

        args:
          - -c
          - |
            echo "Copying theme..."
            cp -R /custom/* /theme

        volumeMounts:
          - name: theme
            mountPath: /theme

    YAML
  ]
}
