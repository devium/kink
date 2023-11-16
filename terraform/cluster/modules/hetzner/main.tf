resource "helm_release" "hcloud_csi" {
  name       = var.release_name
  namespace  = "kube-system"
  repository = "https://charts.hetzner.cloud"
  chart      = "hcloud-csi"
  version    = var.config.version

  values = [<<-YAML
    controller:
      hcloudToken:
        value: "${var.config.hcloud_token}"
  YAML
  ]
}
