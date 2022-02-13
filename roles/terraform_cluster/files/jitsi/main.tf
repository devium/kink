terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

locals {
  jitsi_domain = "${var.subdomains.jitsi}.${var.domain}"
  jitsi_namespace = "jitsi"
  jvb_port_udp = 10000
}

resource "kubectl_manifest" "jitsi_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${local.jitsi_namespace}
  YAML
}

resource "kubectl_manifest" "prosody_plugins" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: prosody-plugins
      namespace: ${local.jitsi_namespace}
    data:
      mod_muc_rooms.lua: |-
        ${replace(file("${path.module}/mod_muc_rooms.lua"), "\n", "\n    ")}
    YAML

  depends_on = [
    kubectl_manifest.jitsi_namespace
  ]
}

resource "helm_release" "jitsi" {
  name = var.release_name
  namespace = local.jitsi_namespace
  create_namespace = true

  repository = "https://jitsi-contrib.github.io/jitsi-helm/"
  chart = "jitsi-meet"
  version = var.versions.jitsi_helm

  values = [ <<-YAML
    publicURL: https://${local.jitsi_domain}
    web:
      image:
        tag: ${var.versions.jitsi}
      ingress:
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: letsencrypt
        enabled: true
        hosts:
          - host: ${local.jitsi_domain}
            paths:
              - /
        tls:
          - secretName: cert-secret
            hosts:
              - ${local.jitsi_domain}

    jvb:
      image:
        tag: ${var.versions.jitsi}
      service:
        enabled: true
      useNodeIP: true
      UDPPort: ${local.jvb_port_udp}

    jicofo:
      image:
        tag: ${var.versions.jitsi}

    prosody:
      image:
        tag: ${var.versions.jitsi}
      persistence:
        enabled: false
      extraEnvs:
        - name: XMPP_MODULES
          value: muc_rooms
      extraVolumeMounts:
        - name: prosody-plugins
          mountPath: /prosody-plugins-custom
      extraVolumes:
        - name: prosody-plugins
          configMap:
            name: prosody-plugins
      ingress:
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: letsencrypt
        enabled: true
        hosts:
          - host: ${local.jitsi_domain}
            paths:
              - /rooms
        tls:
          secretName: cert-secret
          hosts:
            - ${local.jitsi_domain}
    YAML
  ]

  depends_on = [
    kubectl_manifest.prosody_plugins
  ]
}

resource "kubectl_manifest" "ingress_jitsi_jvb_patch" {
  yaml_body = <<-YAML
    apiVersion: helm.cattle.io/v1
    kind: HelmChartConfig
    metadata:
      name: rke2-ingress-nginx
      namespace: kube-system
    spec:
      valuesContent: |-
        udp:
          ${local.jvb_port_udp}: "${local.jitsi_namespace}/${var.release_name}-jitsi-meet-jvb:${local.jvb_port_udp}"
    YAML
}
