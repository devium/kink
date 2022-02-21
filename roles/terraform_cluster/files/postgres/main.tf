terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

locals {
  postgres_namespace = "postgres"
}

resource "kubectl_manifest" "postgres_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${local.postgres_namespace}
  YAML
}

resource "kubectl_manifest" "postgres_volume" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: postgres-volume
      namespace: ${local.postgres_namespace}
    spec:
      accessModes:
        - ReadWriteOnce
      capacity:
        storage: 10Gi
      persistentVolumeReclaimPolicy: Retain
      csi:
        driver: csi.hetzner.cloud
        fsType: ext4
        volumeHandle: "${var.postgres_volume_handle}"
    YAML

  depends_on = [
    kubectl_manifest.postgres_namespace
  ]
}

resource "kubectl_manifest" "postgres_pvc" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: postgres-pvc
      namespace: ${local.postgres_namespace}
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      storageClassName: ""
      volumeName: postgres-volume
    YAML

  depends_on = [
    kubectl_manifest.postgres_namespace
  ]
}

resource "kubectl_manifest" "postgres_init_secret" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: postgres-init
      namespace: ${local.postgres_namespace}
    stringData:
      init.sql: |
        CREATE USER keycloak WITH PASSWORD '${var.db_passwords.keycloak}';
        CREATE DATABASE keycloak WITH OWNER keycloak;
    YAML

  depends_on = [
    kubectl_manifest.postgres_namespace
  ]
}

resource "helm_release" "postgres" {
  name             = var.release_name
  namespace        = local.postgres_namespace
  create_namespace = true

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  values = [<<-YAML
    image:
      tag: ${var.versions.postgres}
    global:
      postgresql:
        auth:
          postgresPassword: ${var.db_passwords.root}
    primary:
      persistence:
        existingClaim: postgres-pvc
      initdb:
        scriptsSecret: postgres-init
        user: postgres
        password: ${var.db_passwords.root}
    YAML
  ]

  depends_on = [
    kubectl_manifest.postgres_init_secret
  ]
}
