locals {
  acme_server = "https://acme${var.use_production_cert ? "" : "-staging"}-v02.api.letsencrypt.org/directory"
}

resource "helm_release" "cert_manager" {
  name       = var.release_name
  namespace  = var.namespaces.cert_manager
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.versions.cert_manager_helm

  values = [<<-YAML
    installCRDs: true

    resources:
      requests:
        memory: ${var.resources.memory.cert_manager}

    webhook:
      resources:
        requests:
          memory: ${var.resources.memory.cert_manager_webhook}

    cainjector:
      resources:
        requests:
          memory: ${var.resources.memory.cert_manager_cainjector}
  YAML
  ]
}

resource "kubernetes_secret_v1" "hetzner_secret" {
  metadata {
    name      = "hetzner-secret"
    namespace = var.namespaces.cert_manager
  }

  data = {
    api-key = var.hdns_token
  }
}

resource "helm_release" "hetzner_webhook" {
  name       = "${var.release_name}-hetzner"
  namespace  = var.namespaces.cert_manager
  repository = "https://vadimkim.github.io/cert-manager-webhook-hetzner"
  chart      = "cert-manager-webhook-hetzner"

  values = [<<-YAML
    groupName: acme.${var.domain}
  YAML
  ]
}

resource "kubectl_manifest" "issuer" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer

    metadata:
      name: letsencrypt

    spec:
      acme:
        server: ${local.acme_server}
        email: ${var.cert_email}

        privateKeySecretRef:
          name: acme-account-key

        solvers:
          - http01:
              ingress:
                class: nginx

          - dns01:
              webhook:
                groupName: acme.${var.domain}
                solverName: hetzner
                config:
                  secretName: hetzner_secret
                  zoneName: ${var.domain}
                  apiUrl: https://dns.hetzner.com/api/v1
  YAML

  depends_on = [
    helm_release.cert_manager
  ]
}
