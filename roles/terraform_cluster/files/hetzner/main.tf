terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
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
  for_each  = data.kubectl_file_documents.csi_documents.manifests
  yaml_body = each.value
}

# Make flannel use the private subnet interface
# Using args instead of the iface value enforces a new pod rollout
resource "kubectl_manifest" "flannel_iface_patch" {
  yaml_body = <<-YAML
    apiVersion: helm.cattle.io/v1
    kind: HelmChartConfig
    metadata:
      name: rke2-canal
      namespace: kube-system
    spec:
      valuesContent: |
        flannel:
          args:
            - --ip-masq
            - --kube-subnet-mgr
            - --iface=ens10
    YAML
}
