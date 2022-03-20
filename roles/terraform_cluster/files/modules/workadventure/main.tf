locals {
  fqdn_front    = "${var.subdomains.workadventure_front}.${var.domain}"
  fqdn_back     = "${var.subdomains.workadventure_back}.${var.domain}"
  fqdn_maps     = "${var.subdomains.workadventure_maps}.${var.domain}"
  fqdn_pusher   = "${var.subdomains.workadventure_pusher}.${var.domain}"
  fqdn_uploader = "${var.subdomains.workadventure_uploader}.${var.domain}"
}

resource "helm_release" "workadventure" {
  name      = var.release_name
  namespace = var.namespaces.workadventure

  repository = "https://devium.github.io/helm-charts/"
  chart      = "workadventure"
  version    = var.versions.workadventure_helm

  values = [<<-YAML
    domain: ${var.domain}

    env:
      jitsiIss: jitsi
      jitsiUrl: ${var.subdomains.jitsi}.${var.domain}
      secretJitsiKey: ${var.jitsi_secrets.jwt}
      jitsiPrivateMode: true

    ingress:
      annotations:
        cert-manager.io/cluster-issuer: ${var.cert_issuer}
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/cors-allow-origin: "https://${local.fqdn_front}/*"

    front:
      ingress:
        tls:
          - secretName: ${local.fqdn_front}-tls

      subdomain: ${var.subdomains.workadventure_front}
      env:
        startRoomUniverse: _
        startRoomPath: ${var.workadventure_start_map}

    back:
      ingress:
        tls:
          - secretName: ${local.fqdn_back}-tls

      subdomain: ${var.subdomains.workadventure_back}
      replicaCount: 1

    pusher:
      ingress:
        tls:
          - secretName: ${local.fqdn_pusher}-tls

      subdomain: ${var.subdomains.workadventure_pusher}

    uploader:
      ingress:
        tls:
          - secretName: ${local.fqdn_uploader}-tls

      subdomain: ${var.subdomains.workadventure_uploader}

    maps:
      ingress:
        tls:
          - secretName: ${local.fqdn_maps}-tls

      subdomain: ${var.subdomains.workadventure_maps}

      volumes: |
        - name: maps
          emptyDir: {}

      volumeMounts: |
        - name: maps
          mountPath: /var/www/html

      initContainers: |
        - name: maps
          image: ${var.workadventure_maps_image}
          imagePullPolicy: IfNotPresent

          command:
            - sh

          args:
            - -c
            - cp -R /maps/* /maps_volume/

          volumeMounts:
            - name: maps
              mountPath: /maps_volume
  YAML
  ]
}
