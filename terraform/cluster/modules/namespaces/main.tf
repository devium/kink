resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(values(var.namespaces))

  metadata {
    name = each.value

    labels = {
      prometheus = "prometheus"
    }
  }
}
