locals {
  pg_dump_script = join(
    "\n",
    [
      for db in var.cluster_vars.db_specs :
      "export PGPASSWORD=${db.password}; pg_dump -h ${var.cluster_vars.db_host} -U ${db.username} ${db.database} > /backup/db/${db.database}_$(date +%Y%m%dT%H%M%S).sql"
    ]
  )
}

resource "kubernetes_secret_v1" "backup_script" {
  metadata {
    name      = "script"
    namespace = var.config.namespace
  }

  data = {
    "backup.sh" = <<-BASH
      set -x
      # Workaround: kill leaking Shlink database connections.
      export PGPASSWORD=${var.cluster_vars.db_specs.shlink.password}; psql -h ${var.cluster_vars.db_host} -U ${var.cluster_vars.db_specs.shlink.username} -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'shlink' AND state = 'idle';"
      mkdir -p /backup/db
      ${local.pg_dump_script}
    BASH
  }
}

resource "kubernetes_cron_job_v1" "backup" {
  metadata {
    name      = "backup"
    namespace = var.config.namespace
  }

  spec {
    schedule = var.config.schedule

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
              image = "bitnami/postgresql"

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
                  memory = var.config.memory
                }
              }
            }
            restart_policy = "OnFailure"

            volume {
              name = "backup-volume"
              persistent_volume_claim {
                claim_name = "backup-pvc"
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
