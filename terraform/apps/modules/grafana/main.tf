locals {
  fqdn     = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
  oidc_url = "https://${var.cluster_vars.domains.keycloak}/realms/${var.cluster_vars.keycloak_realm}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src" = "'self' 'unsafe-inline' 'unsafe-eval'"
  })


  dashboards = {
    for key, value in var.config.dashboards :
    key => {
      url = value,
      datasource = [
        {
          name  = "DS_PROMETHEUS"
          value = "prometheus"
        }
      ]
    }
  }
}

resource "helm_release" "grafana" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.config.version_helm

  values = [<<-YAML
    grafana:
      image:
        tag: ${var.config.version}

      ingress:
        enabled: true

        annotations:
          cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
          nginx.ingress.kubernetes.io/configuration-snippet: |
            more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";

        hosts:
          - ${local.fqdn}

        tls:
          - secretName: ${local.fqdn}-tls
            hosts:
              - ${local.fqdn}

      resources:
        requests:
          memory: ${var.config.memory}

      adminPassword: ${var.config.admin_password}

      dashboards:
        default:
          ${indent(6, yamlencode(local.dashboards))}

      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
          - name: 'default'
            orgId: 1
            folder: ''
            type: file
            disableDeletion: false
            editable: true
            options:
              path: /var/lib/grafana/dashboards/default

      grafana.ini:
        server:
          root_url: https://${local.fqdn}

        database:
          type: postgres
          host: ${var.cluster_vars.db_host}
          name: ${var.config.db.database}
          user: ${var.config.db.username}
          password: ${var.config.db.password}

        auth:
          disable_login_form: true

        auth.generic_oauth:
          name: Keycloak
          icon: signin
          enabled: true
          auto_login: true
          client_id: ${var.config.keycloak.client}
          client_secret: ${var.config.keycloak.secret}
          scopes: openid private_profile
          empty_scopes: false
          auth_url: ${local.oidc_url}/protocol/openid-connect/auth
          token_url: ${local.oidc_url}/protocol/openid-connect/token
          api_url: ${local.oidc_url}/protocol/openid-connect/userinfo
          allow_sign_up: true
          tls_skip_verify_insecure: false
          use_pkce: true
          email_attribute_path: email
          login_attribute_path: sub
          name_attribute_path: preferred_username
          role_attribute_path: contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'grafana_editor') && 'Editor' || 'Viewer'
          # https://github.com/grafana/grafana/issues/70203#issuecomment-1603895013
          oauth_allow_insecure_email_lookup: true

        smtp:
          enabled: true
          host: ${var.cluster_vars.mail_server}
          user: ${var.config.mail.account}@${var.cluster_vars.domains.domain}
          password: ${var.config.mail.password}
          from_address: ${var.config.mail.account}@${var.cluster_vars.domains.domain}
          from_name: ${var.config.mail.display_name}
          startTLS_policy: MandatoryStartTLS

    alertmanager:
      alertmanagerSpec:
        resources:
          requests:
            memory: ${var.config.memory_alertmanager}

    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false

        serviceMonitorNamespaceSelector:
          matchLabels:
            prometheus: prometheus

        resources:
          requests:
            memory: ${var.config.memory_prometheus}
  YAML
  ]
}

resource "helm_release" "loki" {
  name       = "${var.cluster_vars.release_name}-loki"
  namespace  = var.config.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.config.version_loki_helm

  values = [<<-YAML
    loki:
      resources:
        requests:
          memory: ${var.config.memory_loki}

      config:
        query_scheduler:
          max_outstanding_requests_per_tenant: 2048

        query_range:
          parallelise_shardable_queries: false
          split_queries_by_interval: 0

    promtail:
      resources:
        requests:
          memory: ${var.config.memory_promtail}
  YAML
  ]
}
