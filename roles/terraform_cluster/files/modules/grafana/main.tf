locals {
  fqdn     = "${var.subdomains.grafana}.${var.domain}"
  oidc_url = "https://${var.subdomains.keycloak}.${var.domain}/realms/${var.keycloak_realm}"
}

resource "helm_release" "grafana" {
  name       = var.release_name
  namespace  = var.namespaces.grafana
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.versions.grafana_helm

  values = [<<-YAML
    grafana:
      image:
        tag: ${var.versions.grafana}

      ingress:
        enabled: true

        annotations:
          cert-manager.io/cluster-issuer: ${var.cert_issuer}

        hosts:
          - ${local.fqdn}

        tls:
          - secretName: ${local.fqdn}-tls
            hosts:
              - ${local.fqdn}

      resources:
        requests:
          memory: ${var.resources.memory.grafana}

      adminPassword: ${var.admin_passwords.grafana}

      grafana.ini:
        server:
          root_url: https://${local.fqdn}

        database:
          type: postgres
          host: ${var.db_host}
          name: grafana
          user: grafana
          password: ${var.db_passwords.grafana}

        auth:
          disable_login_form: true

        auth.generic_oauth:
          name: Keycloak
          icon: signin
          enabled: true
          client_id: ${var.keycloak_clients.grafana}
          client_secret: ${var.keycloak_secrets.grafana}
          scopes: openid private_profile
          empty_scopes: false
          auth_url: ${local.oidc_url}/protocol/openid-connect/auth
          token_url: ${local.oidc_url}/protocol/openid-connect/token
          api_url: ${local.oidc_url}/protocol/openid-connect/userinfo
          allow_sign_up: true
          tls_skip_verify_insecure: false
          use_pkce: true
          login_attribute_path: sub
          name_attribute_path: preferred_username
          role_attribute_path: contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'grafana_editor') && 'Editor' || 'Viewer'

    alertmanager:
      alertmanagerSpec:
        resources:
          requests:
            memory: ${var.resources.memory.alertmanager}

    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false

        serviceMonitorNamespaceSelector:
          matchLabels:
            prometheus: prometheus

        resources:
          requests:
            memory: ${var.resources.memory.prometheus}
  YAML
  ]
}

resource "helm_release" "loki" {
  name       = "${var.release_name}-loki"
  namespace  = var.namespaces.grafana
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.versions.loki_helm

  values = [<<-YAML
    loki:
      image:
        tag: ${var.versions.loki}

      resources:
        requests:
          memory: ${var.resources.memory.loki}

      config:
        query_scheduler:
          max_outstanding_requests_per_tenant: 2048

        query_range:
          parallelise_shardable_queries: false
          split_queries_by_interval: 0

    promtail:
      resources:
        requests:
          memory: ${var.resources.memory.loki_promtail}
  YAML
  ]
}
