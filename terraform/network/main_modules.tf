module "rke2" {
  source = "./modules/rke2"

  default_csp        = var.default_csp
  mailserver_service = var.mailserver_service
}
