terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

locals {
  namespace = "nextcloud"
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
      name: nextcloud-volume
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
        volumeHandle: "${var.nextcloud_volume_handle}"
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
      name: nextcloud-pvc
      namespace: ${local.namespace}
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      storageClassName: ""
      volumeName: nextcloud-volume
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}


resource "helm_release" "nextcloud" {
  name             = var.release_name
  namespace        = local.namespace
  create_namespace = true

  repository = "https://nextcloud.github.io/helm/"
  chart      = "nextcloud"
  version    = var.versions.nextcloud_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.nextcloud}

    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt
      hosts:
        - host: ${var.subdomains.nextcloud}.${var.domain}
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: cert-secret
          hosts:
            - ${var.subdomains.nextcloud}.${var.domain}

    nextcloud:
      host: ${var.subdomains.nextcloud}.${var.domain}
      username: admin
      password: ${var.nextcloud_admin_password}
      extraEnv:
        - name: OVERWRITEPROTOCOL
          value: https

    internalDatabase:
      enabled: false

    externalDatabase:
      enabled: true
      type: postgresql
      host: ${var.release_name}-postgresql.postgres.svc.cluster.local
      user: nextcloud
      password: ${var.db_passwords.nextcloud}
      database: nextcloud

    persistence:
      enabled: true
      existingClaim: nextcloud-pvc

    YAML
  ]
}
