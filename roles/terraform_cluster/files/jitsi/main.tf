terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

locals {
  jitsi_domain = "${var.jitsi_subdomain}.${var.domain}"
}

resource "helm_release" "jitsi" {
  name = var.release_name
  namespace = "jitsi"
  create_namespace = true

  repository = "https://jitsi-contrib.github.io/jitsi-helm/"
  chart = "jitsi-meet"

  values = [
    yamlencode({
      publicURL = local.jitsi_domain
      web = {
        ingress = {
          enabled = true
          annotations = {
            "kubernetes.io/ingress.class" = "nginx"
            "cert-manager.io/cluster-issuer" = "letsencrypt"
          }
          hosts = [{
            host = local.jitsi_domain
            paths = [
              "/"
            ]
          }]
          tls = [{
            secretName = "cert-secret"
            hosts = [
              local.jitsi_domain
            ]
          }]
        }
      }
      jvb = {
        publicIP = var.floating_ipv4

        service = {
          enabled = true
        }

        useHostPort = true
        useNodeIP = true
      }
    })
  ]
}
