resource "helm_release" "minecraft" {
  name       = var.release_name
  namespace  = var.namespaces.minecraft
  repository = "https://itzg.github.io/minecraft-server-charts/"
  chart      = "minecraft"
  version    = var.versions.minecraft_helm

  values = [<<-YAML
    image:
      tag: ${var.versions.minecraft}

    minecraftServer:
      eula: "TRUE"
      version: ${var.versions.minecraft_game}
      serviceType: NodePort
      nodePort: 30001
      maxPlayers: 8
      pvp: true
      ops: ${var.minecraft_admins}
      type: "SPIGOT"
      worldSaveName: ${var.minecraft_world}

    persistence:
      dataDir:
        enabled: true
        existingClaim: ${var.pvcs.minecraft}

    resources:
      requests:
        memory: 1Gi
  YAML
  ]
}
