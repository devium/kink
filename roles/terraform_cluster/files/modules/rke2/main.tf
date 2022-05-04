# Make flannel use the private subnet interface
# Using args instead of the iface value enforces a new pod rollout
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
          args:
            - --ip-masq
            - --kube-subnet-mgr
            - --iface=ens10
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
      YAML
    }
  }
}
