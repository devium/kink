terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

locals {
  acme_server = "https://acme${var.use_production_cert ? "" : "-staging"}-v02.api.letsencrypt.org/directory"
}

resource "helm_release" "cert_manager" {
  name = var.release_name
  namespace = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  version = var.versions.cert_manager_helm

  values = [
    "installCRDs: true"
  ]
}

resource "kubectl_manifest" "cert_issuer" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt
      namespace: cert-manager
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
    YAML

  depends_on = [
    helm_release.cert_manager
  ]
}
