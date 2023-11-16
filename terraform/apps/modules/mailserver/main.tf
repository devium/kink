locals {
  fqdn     = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
  fullname = "${var.cluster_vars.release_name}-docker-mailserver"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src" = "'self' 'unsafe-eval'"
  })
}

resource "kubernetes_config_map_v1" "config" {
  # The helm chart ConfigMap tries to glob config contents from local files which it won't be able to find.
  metadata {
    name      = "${local.fullname}-configs"
    namespace = var.config.namespace
  }

  data = {
    "postfix-accounts.cf" = file("${var.decryption_path}/${basename(var.config.vault_files.accounts)}")
    "postfix-virtual.cf"  = file("${var.decryption_path}/${basename(var.config.vault_files.aliases)}")
    "KeyTable"            = "mail._domainkey.${var.cluster_vars.domains.domain} ${var.cluster_vars.domains.domain}:mail:/etc/opendkim/keys/${var.cluster_vars.domains.domain}/mail.private"
    "SigningTable"        = "*@${var.cluster_vars.domains.domain} mail._domainkey.${var.cluster_vars.domains.domain}"
    "TrustedHosts"        = <<-HOSTS
      127.0.0.1
      localhost
    HOSTS

    "postfix-main.cf" = <<-CF
      smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination, reject_unauth_pipelining, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname, reject_unknown_recipient_domain, reject_rbl_client zen.spamhaus.org, reject_rbl_client bl.spamcop.net
    CF

    "dovecot-services.cf" = <<-CF
      inet_listener imaps-rainloop {
        port = 10993
        ssl = yes
      }
    CF

    "80-replication.conf" = <<-CONF
      mail_plugins = $mail_plugins notify replication
      service replicator {
        process_min_avail = 1
        unix_listener replicator-doveadm {
          mode = 0600
          user = docker
        }
      }
      service aggregator {
        fifo_listener replication-notify-fifo {
          user = docker
        }
        unix_listener replication-notify {
          user = docker
        }
      }
      
      doveadm_port = 4117
      doveadm_password = secret
      service doveadm {
        inet_listener {
          port = 4117
          ssl = yes
        }
      }
      plugin {
        #mail_replica = tcp:anotherhost.example.com       # use doveadm_port
        #mail_replica = tcp:anotherhost.example.com:12345 # use port 12345 explicitly
      }
    CONF

    "91-override-sieve.conf" = <<-CONF
      plugin {
        sieve = /var/mail/sieve/%d/%n/.dovecot.sieve
        sieve_dir = /var/mail/sieve/%d/%n/sieve
      }
    CONF

    "am-i-healthy.sh" = <<-BASH
      #!/bin/bash
      # this script is intended to be used by periodic kubernetes liveness probes to ensure that the container
      # (and all its dependent services) is healthy
      {{ range .Values.livenessTests.commands -}}
      {{ . }} && \
      {{- end }}
      echo "All healthy"
    BASH
  }
}

resource "kubernetes_secret_v1" "secrets" {
  metadata {
    name      = "${local.fullname}-secrets"
    namespace = var.config.namespace
  }

  data = {
    "${var.cluster_vars.domains.domain}-mail.private" = file("${var.decryption_path}/${basename(var.config.vault_files.key)}")
  }
}

resource "kubernetes_manifest" "cert" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "${local.fqdn}-tls"
      namespace = var.config.namespace
    }

    spec = {
      secretName = "${local.fqdn}-tls"

      issuerRef = {
        name = var.cluster_vars.issuer
        kind = "ClusterIssuer"
      }

      dnsNames = [
        local.fqdn
      ]
    }
  }
}

resource "helm_release" "mailserver" {
  name       = var.cluster_vars.release_name
  namespace  = var.config.namespace
  repository = "https://docker-mailserver.github.io/docker-mailserver-helm/"
  chart      = "docker-mailserver"
  version    = var.config.version_helm

  values = [<<-YAML
    image:
      tag: ${var.config.version}

    pod:
      dockermailserver:
        override_hostname: ${local.fqdn}
        ssl_type: manual

    demoMode:
      enabled: false

    domains:
      - ${var.cluster_vars.domains.domain}

    ssl:
      useExisting: true
      existingName: ${local.fqdn}-tls

    configMap:
      useExisting: true

    secret:
      useExisting: true

    service:
      type: "ClusterIP"

    persistence:
      existingClaim: mailserver-pvc
  YAML
  ]
}
