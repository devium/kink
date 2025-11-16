resource "kubernetes_secret_v1" "init" {
  metadata {
    name      = "init"
    namespace = var.config.namespace
  }

  data = {
    "init.sql" = join("\n", concat(
      [
        for db_spec_key, db_spec in var.cluster_vars.db_specs :
        "CREATE USER ${db_spec.username} WITH PASSWORD '${db_spec.password}';"
      ],
      [
        for db_spec_key, db_spec in var.cluster_vars.db_specs :
        "CREATE DATABASE ${db_spec.database} WITH OWNER ${db_spec.username} ${db_spec.params};"
      ]
    ))
  }
}

resource "helm_release" "postgres" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  values = [<<-YAML
    image:
      repository: bitnamilegacy/postgresql
      tag: ${var.config.version}

    global:
      postgresql:
        auth:
          postgresPassword: ${var.config.password}

    primary:
      persistence:
        existingClaim: postgres-pvc

      initdb:
        scriptsSecret: ${one(kubernetes_secret_v1.init.metadata).name}
        user: postgres
        password: ${var.config.password}

    resources:
      requests:
        memory: ${var.config.memory}
    YAML
  ]
}
