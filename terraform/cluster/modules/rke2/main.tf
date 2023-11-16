# Make flannel use Wireguard instead of VXLAN. This might require a full server restart.
resource "kubernetes_manifest" "flannel_iface_patch" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChartConfig"

    metadata = {
      name      = "rke2-canal"
      namespace = "kube-system"
    }

    spec = {
      valuesContent = <<-YAML
        flannel:
          backend: "wireguard"
      YAML
    }
  }
}

# Allow snippet annotations in ingresses
resource "kubernetes_manifest" "ingress_patch" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChartConfig"

    metadata = {
      name      = "rke2-ingress-nginx"
      namespace = "kube-system"
    }

    spec = {
      valuesContent = <<-YAML
        controller:
          allowSnippetAnnotations: true

          tolerations:
            - key: "CriticalAddonsOnly"
              operator: "Exists"

          addHeaders:
            Content-Security-Policy: "${join(";", [for key, value in var.default_csp : "${key} ${value}"])}"
            X-Content-Type-Options: nosniff
            Referrer-Policy: same-origin

        tcp:
          25: "${var.mailserver_service}:25"
          143: "${var.mailserver_service}:143"
          587: "${var.mailserver_service}:587"
          993: "${var.mailserver_service}:993"
      YAML
    }
  }
}
