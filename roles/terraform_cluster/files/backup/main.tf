terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

locals {
  namespace = "backup"
  backup_databases = [
    {
      username = "keycloak"
      database = "keycloak"
      password = var.db_passwords.keycloak
    },
    {
      username = "hedgedoc"
      database = "hedgedoc"
      password = var.db_passwords.hedgedoc
    },
    {
      username = "nextcloud"
      database = "nextcloud"
      password = var.db_passwords.nextcloud
    },
    {
      username = "synapse"
      database = "synapse"
      password = var.db_passwords.synapse
    }
  ]
  pg_dump_script = join(
    "\n",
    [
      for db in local.backup_databases :
      "export PGPASSWORD=${db.password}; pg_dump -h ${var.release_name}-postgresql.postgres.svc.cluster.local -U ${db.username} ${db.database} > /backup/db/${db.database}_$(date +%Y%m%dT%H%M%S).sql"
    ]
  )
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
      name: backup-volume
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
        volumeHandle: "${var.volume_handles.backup}"
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
      name: backup-pvc
      namespace: ${local.namespace}
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      storageClassName: ""
      volumeName: backup-volume
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "backup_script" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: backup-script
      namespace: ${local.namespace}
    stringData:
      backup.sh: |
        mkdir -p /backup/db
        ${indent(4, local.pg_dump_script)}
    YAML
}

resource "kubectl_manifest" "backup" {
  yaml_body = <<-YAML
    apiVersion: batch/v1
    kind: CronJob
    metadata:
      name: backup
      namespace: ${local.namespace}
    spec:
      schedule: "${var.backup_schedule}"
      jobTemplate:
        spec:
          template:
            spec:
              containers:
                - name: postgres-backup
                  image: bitnami/postgresql:${var.versions.postgres}
                  imagePullPoliciy: IfNotPresent
                  command:
                  - /bin/bash
                  - /backup.sh
                  volumeMounts:
                  - mountPath: /backup
                    name: backup-volume
                  - mountPath: /backup.sh
                    subPath: backup.sh
                    name: backup-script
              restartPolicy: OnFailure
              volumes:
              - name: backup-volume
                persistentVolumeClaim:
                  claimName: ${kubectl_manifest.pvc.name}
              - name: backup-script
                secret:
                  secretName: backup-script
              securityContext:
                runAsUser: 1000
                runAsGroup: 1000
                fsGroup: 1000
                fsGroupChangePolicy: "OnRootMismatch"
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}
