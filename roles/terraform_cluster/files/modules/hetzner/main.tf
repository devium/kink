resource "helm_release" "hcloud_csi" {
  name       = var.release_name
  namespace  = "kube-system"
  repository = "https://charts.hetzner.cloud"
  chart      = "hcloud-csi"
  version    = var.versions.hcloud_csi

  values = [<<-YAML
    controller:
      hcloudToken:
        value: "${var.hcloud_token}"
  YAML
  ]
}
