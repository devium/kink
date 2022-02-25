terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

locals {
  namespace = "postgres"
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
      name: postgres-volume
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
        volumeHandle: "${var.postgres_volume_handle}"
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
      name: postgres-pvc
      namespace: ${local.namespace}
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
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "init_secret" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: postgres-init
      namespace: ${local.namespace}
    stringData:
      init.sql: |
        CREATE USER keycloak WITH PASSWORD '${var.db_passwords.keycloak}';
        CREATE DATABASE keycloak WITH OWNER keycloak;
        CREATE USER hedgedoc WITH PASSWORD '${var.db_passwords.hedgedoc}';
        CREATE DATABASE hedgedoc WITH OWNER hedgedoc;
        CREATE USER nextcloud WITH PASSWORD '${var.db_passwords.nextcloud}';
        CREATE DATABASE nextcloud WITH OWNER nextcloud;
        CREATE USER synapse WITH PASSWORD '${var.db_passwords.synapse}';
        CREATE DATABASE synapse WITH OWNER synapse LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0;
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "helm_release" "postgres" {
  name             = var.release_name
  namespace        = local.namespace
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
    kubectl_manifest.init_secret
  ]
}
