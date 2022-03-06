output "csi_driver" {
  value = coalesce([for manifest in kubernetes_manifest.hcloud_csi : manifest.manifest.kind == "CSIDriver" ? manifest.manifest.metadata.name : null]...)
}