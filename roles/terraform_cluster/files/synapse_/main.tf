terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

locals {
  namespace       = "synapse"
  namespace_nginx = "matrix-static"
  oidc_issuer     = "https://${var.subdomains.keycloak}.${var.domain}/auth/realms/${var.keycloak_realm}"
}


resource "kubectl_manifest" "nginx_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: matrix-static
    YAML
}

resource "kubectl_manifest" "nginx_static" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nginx-static
      namespace: ${local.namespace_nginx}
    data:
      server: |
        {"m.server": "https://${var.subdomains.synapse}.${var.domain}"}
      client: |
        {"m.homeserver": {"base_url": "https://${var.subdomains.synapse}.${var.domain}/"}}
    YAML

  depends_on = [
    kubectl_manifest.nginx_namespace
  ]
}

resource "helm_release" "nginx" {
  name             = var.release_name
  namespace        = local.namespace_nginx
  create_namespace = true

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = var.versions.nginx_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.nginx}

    service:
      type: ClusterIP

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/cors-allow-origin: "*"
      hostname: ${var.domain}
      path: /.well-known/matrix/
      pathType: Prefix
      tls: yes

    staticSiteConfigmap: nginx-static

    serverBlock: |
      server {
        listen 8080;
        location /.well-known/matrix/ {
          alias /app/;
        }
      }
    YAML
  ]

  depends_on = [
    kubectl_manifest.nginx_static
  ]
}


resource "kubectl_manifest" "namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${local.namespace}
  YAML
}

resource "kubectl_manifest" "volume" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: synapse-volume
      namespace: ${local.namespace}
    spec:
      accessModes:
        - ReadWriteOnce
      capacity:
        storage: 10Gi
      persistentVolumeReclaimPolicy: Retain
      csi:
        driver: csi.hetzner.cloud
        fsType: ext4
        volumeHandle: "${var.volume_handles.synapse}"
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "pvc" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: synapse-pvc
      namespace: ${local.namespace}
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      storageClassName: ""
      volumeName: synapse-volume
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
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

    settings:
      report_stats: "no"

    database:
      host: ${var.release_name}-postgresql.postgres.svc.cluster.local
      mode: postgresql
      name: synapse
      password: ${var.db_passwords.synapse}
      port: 5432
      username: synapse

    existingMediaClaim: ${kubectl_manifest.pvc.name}
    podSecurityContext:
      fsGroup: 991
      fsGroupChangePolicy: "OnRootMismatch"

    homeserver:
      server_name: ${var.domain}
      public_baseurl: https://${var.subdomains.synapse}.${var.domain}
      report_stats: false
      send_federation: true
      web_client_location: https://${var.subdomains.element}.${var.domain}

      signing_key_path: "/data/${var.domain}.signing.key"
      media_store_path: /media
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
          client_id: synapse
          client_secret: ${var.keycloak_secrets.synapse}
          scopes: ["openid", "private_profile"]
          authorization_endpoint: ${local.oidc_issuer}/protocol/openid-connect/auth
          token_endpoint: ${local.oidc_issuer}/protocol/openid-connect/token
          userinfo_endpoint: ${local.oidc_issuer}/protocol/openid-connect/userinfo
          user_mapping_provider:
            config:
              localpart_template: "{{ user.sub.split('-')[0] }}"
              display_name_template: "{{ user.preferred_username }}"

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/cors-allow-origin: "*"
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

  depends_on = [
    kubectl_manifest.pvc
  ]
}
