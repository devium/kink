output "namespaces" {
  value = { for key, value in kubernetes_namespace_v1.namespaces : key => one(value.metadata).name }
}
