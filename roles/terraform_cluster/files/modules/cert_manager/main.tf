locals {
  acme_server = "https://acme${var.config.use_production_cert ? "" : "-staging"}-v02.api.letsencrypt.org/directory"
}

resource "helm_release" "cert_manager" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.config.version_helm

  values = [<<-YAML
    installCRDs: true

    resources:
      requests:
        memory: ${var.config.memory}

    webhook:
      resources:
        requests:
          memory: ${var.config.memory_webhook}

    cainjector:
      resources:
        requests:
          memory: ${var.config.memory_cainjector}
  YAML
  ]
}

resource "kubernetes_secret_v1" "hetzner_secret" {
  metadata {
    name      = "hetzner-secret"
    namespace = var.config.namespace
  }

  data = {
    api-key = var.config.hdns_token
  }
}

resource "helm_release" "hetzner_webhook" {
  name       = "${var.cluster_vars.release_name}-hetzner"
  namespace  = var.config.namespace
  repository = "https://vadimkim.github.io/cert-manager-webhook-hetzner"
  chart      = "cert-manager-webhook-hetzner"

  values = [<<-YAML
    groupName: acme.${var.cluster_vars.domains.domain}
  YAML
  ]
}

resource "kubectl_manifest" "issuer" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer

    metadata:
      name: ${var.cluster_vars.issuer}

    spec:
      acme:
        server: ${local.acme_server}
        email: ${var.config.email}

        privateKeySecretRef:
          name: acme-account-key

        solvers:
          - http01:
              ingress:
                class: nginx

          - dns01:
              webhook:
                groupName: acme.${var.cluster_vars.domains.domain}
                solverName: hetzner
                config:
                  secretName: hetzner_secret
                  zoneName: ${var.cluster_vars.domains.domain}
                  apiUrl: https://dns.hetzner.com/api/v1
  YAML

  depends_on = [
    helm_release.cert_manager
  ]
}
