terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

resource "kubectl_manifest" "hcloud_token" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: hcloud-csi
      namespace: kube-system
    stringData:
      token: ${var.hcloud_token}
    YAML
}

data "http" "csi_manifest" {
  url = "https://raw.githubusercontent.com/hetznercloud/csi-driver/${var.versions.hcloud_csi}/deploy/kubernetes/hcloud-csi.yml"
}

data "kubectl_file_documents" "csi_documents" {
  content = data.http.csi_manifest.body
}

resource "kubectl_manifest" "hcloud_csi" {
  for_each = data.kubectl_file_documents.csi_documents.manifests
  yaml_body = each.value
}
