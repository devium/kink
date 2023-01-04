locals {
  fqdn      = "${var.subdomains.minecraft}.${var.domain}"
  fqdn_rcon = "${var.subdomains.minecraft_rcon}.${var.domain}"

  csp = merge(var.default_csp, {
    "script-src" = "'self' 'unsafe-inline'"
    "style-src"  = "'self' 'unsafe-inline' https://fonts.googleapis.com"
  })
}

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
      type: "PAPER"
      worldSaveName: ${var.minecraft_world}
      levelSeed: "8624896"
      memory: 4096M

      spigetResources:
        - 390 # Multiverse-Core
        - 74429 # Fast Chunk Pregenerator
        - 57242 # Spark

      extraPorts:
        - name: dynmap
          containerPort: 8123
          protocol: TCP
          
          service:
            enabled: true
            type: ClusterIP
            port: 8123
          
          ingress:
            ingressClassName: nginx
            enabled: true
            
            annotations:
              cert-manager.io/cluster-issuer: ${var.cert_issuer}
              nginx.ingress.kubernetes.io/configuration-snippet: |
                more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";
              
            hosts:
              - name: ${local.fqdn}
                path: /

            tls:
              - secretName: ${local.fqdn}-tls
                hosts:
                  - ${local.fqdn}

      rcon:
        enabled: true
        serviceType: NodePort
        nodePort: 30002
        password: ${var.minecraft_rcon_password}

    persistence:
      dataDir:
        enabled: true
        existingClaim: ${var.pvcs.minecraft}

    resources:
      requests:
        memory: 4Gi

    nodeSelector:
      kubernetes.io/hostname: gaming

    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Exists"

    mcbackup:
      enabled: true
      backupInterval: 3h
      pruneBackupsDays: 1

      persistence:
        backupDir:
          enabled: true
          existingClaim: ${var.pvcs.minecraft_backup}
  YAML
  ]
}

resource "helm_release" "rcon_web" {
  name       = "${var.release_name}-rcon"
  namespace  = var.namespaces.minecraft
  repository = "https://itzg.github.io/minecraft-server-charts/"
  chart      = "rcon-web-admin"
  version    = var.versions.minecraft_rcon_web_helm

  values = [<<-YAML
    ingress:
      enabled: true
      ingressClassName: nginx
      enabled: true
      
      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";
        
      host: ${local.fqdn_rcon}

      tls:
        - secretName: ${local.fqdn_rcon}-tls
          hosts:
            - ${local.fqdn_rcon}

    rconWeb:
      rconHost: ${local.fqdn}
      rconPort: 30002
      rconPassword: ${var.minecraft_rcon_password}
      isAdmin: true
      username: admin
      password: ${var.minecraft_rcon_web_password}
  YAML
  ]
}

resource "helm_release" "minecraft_bedrock" {
  name       = "${var.release_name}-bedrock"
  namespace  = var.namespaces.minecraft
  repository = "https://itzg.github.io/minecraft-server-charts/"
  chart      = "minecraft-bedrock"
  version    = var.versions.minecraft_bedrock_helm

  values = [<<-YAML
    minecraftServer:
      eula: "TRUE"
      serviceType: NodePort
      nodePort: 30003
      maxPlayers: 8
      pvp: true
      ops: ${var.minecraft_admins}
      levelSeed: "8624896"
      serverName: "${title(var.project_name)}"
      playerIdleTimeout: 0
      cheats: true
      tickDistance: 8
      viewDistance: 20

    persistence:
      dataDir:
        enabled: true
        existingClaim: ${var.pvcs.minecraft_bedrock}

    resources:
      requests:
        memory: 2Gi

    nodeSelector:
      kubernetes.io/hostname: gaming

    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Exists"
  YAML
  ]
}
