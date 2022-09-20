locals {
  fqdn = "${var.subdomains.minecraft}.${var.domain}"

  csp = merge(var.default_csp, {
    "script-src" = "'self' 'unsafe-inline'"
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

      spigetResources:
        - 274 # DynMap
        - 390 # Multiverse-Core
        - 74429 # Fast Chunk Pregenerator

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

    persistence:
      dataDir:
        enabled: true
        existingClaim: ${var.pvcs.minecraft}

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
