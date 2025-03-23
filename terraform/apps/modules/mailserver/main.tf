locals {
  fqdn     = "${var.config.subdomain}.${var.cluster_vars.domains.domain}"
  fullname = "${var.cluster_vars.release_name}-docker-mailserver"

  csp = merge(var.cluster_vars.default_csp, {
    "script-src" = "'self' 'unsafe-eval'"
  })
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
      
    deployment:
      env:
        OVERRIDE_HOSTNAME: ${local.fqdn}

    certificate: ${local.fqdn}-tls

    configMaps:
      postfix-accounts.cf:
        create: true
        path: /tmp/docker-mailserver/postfix-accounts.cf
        data: |
          ${indent(6, file("${var.decryption_path}/${basename(var.config.vault_files.accounts)}"))}

      postfix-virtual.cf:
        create: true
        path: /tmp/docker-mailserver/postfix-virtual.cf
        data: |
          ${indent(6, join("\n", [for alias, account in var.config.aliases : "${alias}@${var.cluster_vars.domains.domain} ${account}@${var.cluster_vars.domains.domain}"]))}

      key-table:
        create: true
        path: /tmp/docker-mailserver/opendkim/KeyTable
        data: "mail._domainkey.${var.cluster_vars.domains.domain} ${var.cluster_vars.domains.domain}:mail:/etc/opendkim/keys/${var.cluster_vars.domains.domain}/mail.private"

      signing-table:
        create: true
        path: /tmp/docker-mailserver/opendkim/SigningTable
        data: "*@${var.cluster_vars.domains.domain} mail._domainkey.${var.cluster_vars.domains.domain}"

    secrets:
      mail.private:
        name: mail.private
        create: true
        path: ${var.cluster_vars.domains.domain}-mail.private
        data: ${base64encode(file("${var.decryption_path}/${basename(var.config.vault_files.key)}"))}

    securityContext:
      fsGroup: 5000

    persistence:
      mail-config:
        enabled: false

      mail-data:
        existingClaim: mailserver-pvc

      mail-state:
        enabled: false

      mail-log:
        enabled: false

    resources:
      requests:
        memory: ${var.config.memory}
  YAML
  ]
}
