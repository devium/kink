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
    enableAuth: true

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
      extraEnvs:
        TOKEN_AUTH_URL: https://${var.subdomains.jitsi_keycloak}.${local.jitsi_domain}/{room}

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
        - name: AUTH_TYPE
          value: jwt
        - name: JWT_APP_ID
          value: jitsi
        - name: JWT_APP_SECRET
          value: ${var.jitsi_jwt_secret}
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
          - secretName: cert-secret
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

data "kubectl_file_documents" "jitsi_keycloak_documents" {
  content = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: jitsi-keycloak-config
      namespace: ${local.jitsi_namespace}
    stringData:
      keycloak.json: |-
        {
          "realm": "${var.keycloak_realm}",
          "auth-server-url": "https://${var.subdomains.keycloak}.${var.domain}/auth/",
          "ssl-required": "external",
          "resource": "jitsi",
          "public-client": true,
          "credentials": {
            "secret": "${var.jitsi_jwt_secret}"
          },
          "confidential-port": 0
        }
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: jitsi-keycloak
      namespace: ${local.jitsi_namespace}
      labels:
        app: jitsi-keycloak
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: jitsi-keycloak

      template:
        metadata:
          labels:
            app: jitsi-keycloak
        spec:
          containers:
            - name: jitsi-keycloak
              image: ghcr.io/devium/jitsi-keycloak
              ports:
                - containerPort: 3000
              env:
                - name: JITSI_SECRET
                  value: ${var.jitsi_jwt_secret}
                - name: DEFAULT_ROOM
                  value: meeting
                - name: JITSI_URL
                  value: https://${local.jitsi_domain}/
                - name: JITSI_SUB
                  value: ${local.jitsi_domain}
              volumeMounts:
                - name: keycloak-config
                  mountPath: /config/keycloak.json
                  subPath: keycloak.json
          volumes:
            - name: keycloak-config
              secret:
                secretName: jitsi-keycloak-config

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: jitsi-keycloak
      namespace: ${local.jitsi_namespace}
    spec:
      selector:
        app: jitsi-keycloak
      ports:
        - protocol: TCP
          port: 80
          targetPort: 3000

    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: jitsi-keycloak
      namespace: ${local.jitsi_namespace}
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt

    spec:
      ingressClassName: nginx
      rules:
        - host: ${var.subdomains.jitsi_keycloak}.${local.jitsi_domain}
          http:
            paths:
              - backend:
                  service:
                    name: jitsi-keycloak
                    port:
                      number: 80
                path: /
                pathType: Prefix
      tls:
        - hosts:
          - ${var.subdomains.jitsi_keycloak}.${local.jitsi_domain}
          secretName: cert-secret-jitsi-keycloak
    YAML
}

resource "kubectl_manifest" "jitsi_keycloak" {
  for_each = data.kubectl_file_documents.jitsi_keycloak_documents.manifests
  yaml_body = each.value
}
