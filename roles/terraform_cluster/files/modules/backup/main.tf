locals {
  backup_databases = [
    {
      username = "keycloak"
      database = "keycloak"
      password = var.db_passwords.keycloak
    },
    {
      username = "grafana"
      database = "grafana"
      password = var.db_passwords.grafana
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
      username = "pretix"
      database = "pretix"
      password = var.db_passwords.pretix
    },
    {
      username = "synapse"
      database = "synapse"
      password = var.db_passwords.synapse
    },
    {
      username = "shlink"
      database = "shlink"
      password = var.db_passwords.shlink
    }
  ]
  pg_dump_script = join(
    "\n",
    [
      for db in local.backup_databases :
      "export PGPASSWORD=${db.password}; pg_dump -h ${var.db_host} -U ${db.username} ${db.database} > /backup/db/${db.database}_$(date +%Y%m%dT%H%M%S).sql"
    ]
  )
}

resource "kubernetes_secret_v1" "backup_script" {
  metadata {
    name      = "script"
    namespace = var.namespaces.backup
  }

  data = {
    "backup.sh" = <<-BASH
      set -x
      # Workaround: kill leaking Shlink database connections.
      export PGPASSWORD=${var.db_passwords.shlink}; psql -h ${var.db_host} -U shlink -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'shlink' AND state = 'idle';"
      mkdir -p /backup/db
      ${local.pg_dump_script}
    BASH
  }
}

resource "kubernetes_cron_job_v1" "backup" {
  metadata {
    name      = "backup"
    namespace = var.namespaces.backup
  }

  spec {
    schedule = var.backup_schedule

    job_template {
      metadata {
        name = "backup"
      }

      spec {
        template {
          metadata {
            name = "backup"
          }

          spec {
            container {
              name  = "postgres-backup"
              image = "bitnami/postgresql:${var.versions.postgres}"

              command = [
                "/bin/bash",
                "/backup.sh"
              ]

              volume_mount {
                mount_path = "/backup"
                name       = "backup-volume"
              }

              volume_mount {
                mount_path = "/backup.sh"
                sub_path   = "backup.sh"
                name       = "backup-script"
              }

              resources {
                requests = {
                  memory = var.resources.memory.backup
                }
              }
            }
            restart_policy = "OnFailure"

            volume {
              name = "backup-volume"
              persistent_volume_claim {
                claim_name = var.pvcs.backup
              }
            }

            volume {
              name = "backup-script"
              secret {
                secret_name = one(kubernetes_secret_v1.backup_script.metadata).name
              }
            }

            security_context {
              run_as_user  = 1000
              run_as_group = 1000
              fs_group     = 1000
            }
          }
        }
      }
    }
  }
}
