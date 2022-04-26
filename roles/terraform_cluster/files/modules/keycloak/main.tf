locals {
  fqdn = "${var.subdomains.keycloak}.${var.domain}"
}

resource "helm_release" "keycloak" {
  name       = var.release_name
  namespace  = var.namespaces.keycloak
  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloakx"
  version    = var.versions.keycloak_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.keycloak}

    ingress:
      enabled: true

      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/proxy-buffer-size: "128k"
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: frame-ancestors https://*.${var.domain}";

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
        memory: ${var.resources.memory.keycloak}

    args:
      - start
      - --auto-build
      - --http-enabled=true
      - --http-port=8080
      - --hostname-strict=false
      - --hostname-strict-https=false

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
          KEYCLOAK_ADMIN_PASSWORD: ${var.admin_passwords.keycloak}

    http:
      relativePath: ""

    extraVolumeMounts: |
      - name: theme
        mountPath: /opt/keycloak/themes/custom

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

    database:
      vendor: postgres
      hostname: ${var.db_host}
      port: 5432
      database: keycloak
      username: keycloak
      password: ${var.db_passwords.keycloak}
  YAML
  ]
}
