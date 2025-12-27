locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src" = "'self' 'unsafe-inline'"
    "style-src"  = "'self' 'unsafe-inline' https://fonts.googleapis.com"
  })
}

resource "helm_release" "minecraft" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://itzg.github.io/minecraft-server-charts/"
  chart      = "minecraft"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    minecraftServer:
      eula: "TRUE"
      version: "${var.config.version_game}"
      serviceType: NodePort
      nodePort: 30001
      maxPlayers: 8
      pvp: true
      ops: ${var.config.admins}
      type: "PAPER"
      worldSaveName: ${var.config.world}
      levelSeed: "${var.config.seed}"
      memory: 12G
      downloadModpackUrl: ${var.config.modpack_url}
      removeOldMods: true

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
              cert-manager.io/cluster-issuer: ${var.cluster_vars.issuer}
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
        password: ${var.config.rcon_password}

    persistence:
      dataDir:
        enabled: true
        existingClaim: minecraft-pvc

    resources:
      requests:
        memory: 12Gi

    nodeSelector:
      kubernetes.io/hostname: gaming

    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Exists"

    mcbackup:
      enabled: true
      backupInterval: 4h
      pruneBackupsDays: 1

      persistence:
        backupDir:
          enabled: true
          existingClaim: minecraft-backup-pvc
  YAML
  ]
}
