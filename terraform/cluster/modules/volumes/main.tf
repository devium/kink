# https://github.com/hashicorp/terraform-provider-kubernetes/issues/872
resource "kubernetes_storage_class_v1" "existing_volume" {
  metadata {
    name = "existing-volume"
  }

  reclaim_policy      = "Retain"
  storage_provisioner = "nfs"
}

resource "kubernetes_persistent_volume_v1" "volumes" {
  for_each = var.volume_config

  metadata {
    name = replace(each.key, "_", "-")
  }

  spec {
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = one(kubernetes_storage_class_v1.existing_volume.metadata).name

    capacity = {
      storage = each.value.size
    }

    persistent_volume_source {
      csi {
        driver        = "csi.hetzner.cloud"
        fs_type       = "ext4"
        volume_handle = each.value.handle
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "pvcs" {
  for_each = var.volume_config

  metadata {
    name      = "${replace(each.key, "_", "-")}-pvc"
    namespace = var.namespaces[each.key]
  }

  spec {
    access_modes       = one(kubernetes_persistent_volume_v1.volumes[each.key].spec).access_modes
    storage_class_name = one(kubernetes_storage_class_v1.existing_volume.metadata).name
    volume_name        = one(kubernetes_persistent_volume_v1.volumes[each.key].metadata).name

    resources {
      requests = {
        storage = one(kubernetes_persistent_volume_v1.volumes[each.key].spec).capacity.storage
      }
    }
  }
}
