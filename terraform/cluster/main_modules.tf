module "rke2" {
  source = "./modules/rke2"

  default_csp        = var.default_csp
  mailserver_service = "${var.namespaces.mailserver}/${var.release_name}-docker-mailserver"
}

module "hetzner" {
  source = "./modules/hetzner"

  config       = var.hetzner_config
  release_name = var.release_name

  depends_on = [
    module.rke2
  ]
}

module "namespaces" {
  source = "./modules/namespaces"

  namespaces = var.namespaces

  depends_on = [
    module.rke2
  ]
}

module "cert_manager" {
  source = "./modules/cert_manager"

  config       = var.cert_manager_config
  domain       = var.domain
  release_name = var.release_name

  depends_on = [
    module.hetzner,
    module.namespaces
  ]
}

module "volumes" {
  source = "./modules/volumes"

  namespaces    = var.namespaces
  volume_config = var.volume_config

  depends_on = [
    module.namespaces
  ]
}
