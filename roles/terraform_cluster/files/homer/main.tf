terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

locals {
  namespace = "homer"
}

resource "kubectl_manifest" "namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${local.namespace}
    YAML
}

resource "kubectl_manifest" "homer_deployment" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: homer
      namespace: ${local.namespace}
      labels:
        app: homer
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: homer

      template:
        metadata:
          labels:
            app: homer
        spec:
          initContainers:
            - name: homer-assets
              image: ${var.homer_assets_image}
              imagePullPolicy: Always
              command:
                - sh
              args:
                - -c
                - |
                  echo "Copying assets..."
                  cp -R /assets/* /assets_volume
              volumeMounts:
                - name: assets
                  mountPath: /assets_volume

          containers:
            - name: homer
              image: b4bz/homer:${var.versions.homer}
              ports:
                - containerPort: 8080
              volumeMounts:
                - name: assets
                  mountPath: /www/assets
                - name: config
                  mountPath: /www/assets/config.yml
                  subPath: config.yml
                - name: config
                  mountPath: /www/rooms.html
                  subPath: rooms.html

          volumes:
            - name: assets
              emptyDir: {}
            - name: config
              configMap:
                name: config
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "homer_service" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: homer
      namespace: ${local.namespace}
    spec:
      selector:
        app: homer
      ports:
        - protocol: TCP
          port: 80
          targetPort: 8080
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "homer_ingress_redirect" {
  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: homer-redirect
      namespace: ${local.namespace}
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt
        nginx.ingress.kubernetes.io/permanent-redirect: "https://${var.subdomains.homer}.${var.domain}$uri"

    spec:
      rules:
        - host: ${var.domain}
          http:
            paths:
              - backend:
                  service:
                    name: homer
                    port:
                      number: 80
                path: /
                pathType: Prefix
      tls:
        - hosts:
          - ${var.domain}
          secretName: cert-secret-homer-redirect
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "homer_ingress" {
  yaml_body = <<-YAML
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: homer
      namespace: ${local.namespace}
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt

    spec:
      rules:
        - host: ${var.subdomains.homer}.${var.domain}
          http:
            paths:
              - backend:
                  service:
                    name: homer
                    port:
                      number: 80
                path: /
                pathType: Prefix
      tls:
        - hosts:
          - ${var.subdomains.homer}.${var.domain}
          secretName: cert-secret-homer
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}

data "template_file" "config" {
  template = file("${path.module}/config.yml.tftpl")
  vars = {
    title               = title(var.project_name)
    subdomain_homer     = var.subdomains.homer
    subdomain_keycloak  = var.subdomains.keycloak
    subdomain_hedgedoc  = var.subdomains.hedgedoc
    subdomain_element   = var.subdomains.element
    subdomain_jitsi     = var.subdomains.jitsi
    subdomain_nextcloud = var.subdomains.nextcloud
    domain              = var.domain
    keycloak_realm      = var.keycloak_realm
  }
}

data "template_file" "rooms" {
  template = file("${path.module}/rooms.html.tftpl")
  vars = {
    jitsi_domain = "${var.subdomains.jitsi}.${var.domain}"
  }
}

resource "kubectl_manifest" "config" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: config
      namespace: ${local.namespace}
    data:
      config.yml: |
        ${indent(4, data.template_file.config.rendered)}
      rooms.html: |
        ${indent(4, data.template_file.rooms.rendered)}
    YAML

  depends_on = [
    kubectl_manifest.namespace
  ]
}
