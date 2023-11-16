output "pvcs" {
  value = { for key, value in kubernetes_persistent_volume_claim_v1.pvcs : key => one(value.metadata).name }
}