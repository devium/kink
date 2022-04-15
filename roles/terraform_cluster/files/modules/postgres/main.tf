resource "kubernetes_secret_v1" "init" {
  metadata {
    name      = "init"
    namespace = var.namespaces.postgres
  }

  data = {
    "init.sql" = <<-YAML
      CREATE USER keycloak WITH PASSWORD '${var.db_passwords.keycloak}';
      CREATE DATABASE keycloak WITH OWNER keycloak;
      CREATE USER hedgedoc WITH PASSWORD '${var.db_passwords.hedgedoc}';
      CREATE DATABASE hedgedoc WITH OWNER hedgedoc;
      CREATE USER nextcloud WITH PASSWORD '${var.db_passwords.nextcloud}';
      CREATE DATABASE nextcloud WITH OWNER nextcloud;
      CREATE USER synapse WITH PASSWORD '${var.db_passwords.synapse}';
      CREATE DATABASE synapse WITH OWNER synapse LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0;
      CREATE USER grafana WITH PASSWORD '${var.db_passwords.grafana}';
      CREATE DATABASE grafana WITH OWNER grafana;
      CREATE USER shlink WITH PASSWORD '${var.db_passwords.shlink}';
      CREATE DATABASE shlink WITH OWNER shlink;
      CREATE USER pretix WITH PASSWORD '${var.db_passwords.pretix}';
      CREATE DATABASE pretix WITH OWNER pretix;
    YAML
  }
}

resource "helm_release" "postgres" {
  name       = var.release_name
  namespace  = var.namespaces.postgres
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  values = [<<-YAML
    image:
      tag: ${var.versions.postgres}

    global:
      postgresql:
        auth:
          postgresPassword: ${var.db_passwords.postgres}

    primary:
      persistence:
        existingClaim: ${var.pvcs.postgres}

      initdb:
        scriptsSecret: ${one(kubernetes_secret_v1.init.metadata).name}
        user: postgres
        password: ${var.db_passwords.postgres}

    resources:
      requests:
        memory: ${var.resources.memory.postgres}
    YAML
  ]
}
