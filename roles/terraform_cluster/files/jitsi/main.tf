terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

locals {
  jitsi_domain = "${var.jitsi_subdomain}.${var.domain}"
  jitsi_namespace = "jitsi"
  jvb_port_udp = 10000
}

resource "helm_release" "jitsi" {
  name = var.release_name
  namespace = local.jitsi_namespace
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
        useNodeIP = true
        UDPPort = local.jvb_port_udp
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

resource "kubectl_manifest" "jvb_port_mapping" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind = "ConfigMap"
    metadata = {
      name = "jitsi-jvb-port-mapping"
      namespace = "kube-system"
    }
    data = {
      (local.jvb_port_udp) = "${local.jitsi_namespace}/${var.release_name}-jitsi-meet-jvb:${local.jvb_port_udp}"
    }
  })
}

resource "kubectl_manifest" "ingress_jitsi_jvb_ports" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind = "Service"
    metadata = {
      name = "rke2-ingress-nginx-controller-admission"
      namespace = "kube-system"
    }
    spec = {
      ports = [{
        name = "jitsi-jvb-udp"
        port = local.jvb_port_udp
        protocol = "UDP"
      }]
    }
  })
}
