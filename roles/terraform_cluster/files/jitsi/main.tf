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
      publicURL = "https://${local.jitsi_domain}"
      web = {
        image = {
          tag = var.jitsi_version
        }
        ingress = {
          enabled = true
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
        image = {
          tag = var.jitsi_version
        }
        service = {
          enabled = true
        }

        useHostPort = true
        useNodeIP = true
      }

      jicofo = {
        image = {
          tag = var.jitsi_version
        }
      }


      prosody = {
        image = {
          tag = var.jitsi_version
        }

        persistence = {
          enabled = false
        }
      }
    })
  ]
}
