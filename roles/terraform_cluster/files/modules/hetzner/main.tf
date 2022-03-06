resource "kubernetes_secret_v1" "hcloud_token" {
  metadata {
    name      = "hcloud-csi"
    namespace = var.namespaces.hetzner
  }

  data = {
    token = var.hcloud_token
  }
}

data "http" "csi_manifest" {
  url = "https://raw.githubusercontent.com/hetznercloud/csi-driver/${var.versions.hcloud_csi}/deploy/kubernetes/hcloud-csi.yml"
}

locals {
  csi_manifest_fixed      = replace(data.http.csi_manifest.body, "/(?s:(kind: StorageClass.*?))\\s*namespace: kube-system/", "$1")
  csi_manifest_namespaced = replace(local.csi_manifest_fixed, "namespace: kube-system", "namespace: ${var.namespaces.hetzner}")
  csi_documents           = split("\n---\n", local.csi_manifest_namespaced)
}

resource "kubernetes_manifest" "hcloud_csi" {
  count    = length(local.csi_documents)
  manifest = yamldecode(local.csi_documents[count.index])

  depends_on = [
    kubernetes_secret_v1.hcloud_token
  ]
}

# Make flannel use the private subnet interface
# Using args instead of the iface value enforces a new pod rollout
resource "kubernetes_manifest" "flannel_iface_patch" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChartConfig"

    metadata = {
      name      = "rke2-canal"
      namespace = var.namespaces.hetzner
    }

    spec = {
      valuesContent = <<-YAML
        |
        flannel:
          args:
            - --ip-masq
            - --kube-subnet-mgr
            - --iface=ens10
        YAML
    }
  }
}
