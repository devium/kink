terraform {
  backend "local" {
  }

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

provider "kubectl" {
  config_path = var.kubeconf_file
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconf_file
  }
}

resource "kubectl_manifest" "secrets" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind = "Secret"
    metadata = {
      name = "hcloud-csi"
      namespace = "kube-system"
    }
    stringData = {
      token: var.hcloud_token
    }
  })
}

data "http" "csi_manifest" {
  url = "https://raw.githubusercontent.com/hetznercloud/csi-driver/${var.hcloud_csi_version}/deploy/kubernetes/hcloud-csi.yml"
}

data "kubectl_file_documents" "csi_documents" {
  content = data.http.csi_manifest.body
}

resource "kubectl_manifest" "hcloud_csi" {
  for_each = data.kubectl_file_documents.csi_documents.manifests
  yaml_body = each.value
}
