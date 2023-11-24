locals {
  fqdn = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"

  csp = merge(var.cluster_vars.default_csp, {
  })

  env = {
    # REACT_APP_API_BASE_URL                      = "https://${var.config.subdomain}.${var.cluster_vars.domains.domain}"
    # REACT_APP_BOT_USER_ID                       = var.config.bot_username
    # REACT_APP_HOME_SERVER_URL                   = "https://${var.cluster_vars.domains.domain}"
    # REACT_APP_ELEMENT_URL                       = "https://${var.cluster_vars.domains.element}"
    # REACT_APP_PRIMARY_COLOR                     = "#b0131d"
    # REACT_APP_DEFAULT_MEETING_MINUTES           = 60
    # REACT_APP_DEFAULT_BREAKOUT_SESSION_MINUTES  = 15
    # REACT_APP_DEFAULT_MINUTES_TO_ROUND          = 15
    # REACT_APP_MESSAGING_NOT_ALLOWED_POWER_LEVEL = 100
    # REACT_APP_DISPLAY_ALL_MEETINGS              = true
  }

  env_bot = {
    HOMESERVER_URL               = "https://${var.cluster_vars.domains.domain}"
    ACCESS_TOKEN                 = var.config.bot_token
    MEETINGWIDGET_URL            = "https://${var.config.subdomain}.${var.cluster_vars.domains.domain}/#/"
    MEETINGWIDGET_NAME           = "NeoDateFix"
    MEETINGWIDGET_COCKPIT_URL    = "https://${var.config.subdomain}.${var.cluster_vars.domains.domain}/cockpit/#/"
    MEETINGWIDGET_COCKPIT_NAME   = "NeoDateFix Details"
    BREAKOUT_SESSION_WIDGET_URL  = "https://${var.config.subdomain}.${var.cluster_vars.domains.domain}/#/"
    BREAKOUT_SESSION_WIDGET_NAME = "Breakout Sessions"
    CALENDAR_ROOM_NAME           = "NeoDateFix"
    LOG_LEVEL                    = "error"
    PORT                         = 3000
    # AUTO_DELETION_OFFSET=0
    # DEFAULT_EVENTS_CONFIG="conf/default_events.json"
    # DEFAULT_WIDGET_LAYOUTS_CONFIG="conf/default_widget_layouts.json"
    # BOT_DISPLAYNAME="NeoDateFix"
    # MATRIX_SERVER_EVENT_MAX_AGE_MINUTES=5
    # STORAGE_FILE_DATA_PATH=storage
    # STORAGE_FILE_FILENAME=bot.json
    MATRIX_LINK_SHARE                 = "https://matrix.to/#/"
    MATRIX_FILTER_APPLY               = true
    MATRIX_FILTER_TIMELINE_LIMIT      = 1000
    ENABLE_WELCOME_WORKFLOW           = true
    WELCOME_WORKFLOW_DEFAULT_LOCALE   = "de"
    ENABLE_CONTROL_ROOM_MIGRATION     = false
    ENABLE_PRIVATE_ROOM_ERROR_SENDING = true
    # JITSI_DIAL_IN_JSON_URL=
    # JITSI_PIN_URL=
    # OPEN_XCHANGE_MEETING_URL_TEMPLATE=
    # ENABLE_GUEST_USER_POWER_LEVEL_CHANGE=false
    # GUEST_USER_PREFIX=@guest-
    # GUEST_USER_DEFAULT_POWER_LEVEL=0
    # GUEST_USER_DELETE_POWER_LEVEL_ON_LEAVE=true
  }
}

resource "kubernetes_deployment_v1" "neodatefix" {
  metadata {
    name      = "neodatefix"
    namespace = var.config.namespace

    labels = {
      app = "neodatefix"
    }
  }

  timeouts {
    create = "30s"
    update = "30s"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "neodatefix"
      }
    }

    template {
      metadata {
        labels = {
          app = "neodatefix"
        }
      }

      spec {
        container {
          image = "ghcr.io/nordeck/matrix-meetings-widget:${var.config.version}"
          name  = "neodatefix"
          args = [
            "server"
          ]

          port {
            container_port = 8080
          }

          resources {
            requests = {
              memory = var.config.memory
            }
          }

          dynamic "env" {
            for_each = local.env

            content {
              name  = env.key
              value = env.value
            }
          }
        }
      }
    }
  }
}

# resource "kubernetes_deployment_v1" "neodatefix_bot" {
#   metadata {
#     name      = "neodatefix-bot"
#     namespace = var.config.namespace

#     labels = {
#       app = "neodatefix-bot"
#     }
#   }

#   timeouts {
#     create = "60s"
#     update = "60s"
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "neodatefix-bot"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "neodatefix-bot"
#         }
#       }

#       spec {
#         container {
#           image = "ghcr.io/nordeck/matrix-meetings-bot:${var.config.version_bot}"
#           name  = "neodatefix"
#           args = [
#             "server"
#           ]

#           port {
#             container_port = 8080
#           }

#           resources {
#             requests = {
#               memory = var.config.memory
#             }
#           }

#           dynamic "env" {
#             for_each = local.env_bot

#             content {
#               name  = env.key
#               value = env.value
#             }
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service_v1" "neodatefix" {
#   metadata {
#     name      = "neodatefix"
#     namespace = var.config.namespace
#   }

#   spec {
#     selector = {
#       app = one(kubernetes_deployment_v1.neodatefix.metadata).labels.app
#     }

#     port {
#       name        = "http"
#       protocol    = "TCP"
#       port        = 8080
#       target_port = 8080
#     }
#   }
# }

# resource "kubernetes_ingress_v1" "neodatefix" {
#   metadata {
#     name      = "neodatefix"
#     namespace = var.config.namespace

#     annotations = {
#       "cert-manager.io/cluster-issuer"                    = var.cluster_vars.issuer
#       "nginx.ingress.kubernetes.io/configuration-snippet" = <<-CONF
#         more_set_headers "Content-Security-Policy: ${join(";", [for key, value in local.csp : "${key} ${value}"])}";
#       CONF
#     }
#   }

#   spec {
#     rule {
#       host = local.fqdn

#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"

#           backend {
#             service {
#               name = one(kubernetes_service_v1.neodatefix.metadata).name

#               port {
#                 number = 8080
#               }
#             }
#           }
#         }
#       }
#     }

#     tls {
#       secret_name = "${local.fqdn}-tls"

#       hosts = [
#         local.fqdn
#       ]
#     }
#   }
# }
