resource "local_file" "AnsibleInventory" {
  content = yamlencode({
    all = {
      hosts = {
        for k, worker in concat([module.master], module.worker): worker.name => {
          ansible_host = worker.ipv4_address
        }
      }
      vars = {
        floating_ip = {
          ipv4_address = module.network.floating_ipv4
          ipv6_address = module.network.floating_ipv6
        }
        network_id = module.network.network_id
      }
      children = {
        workers = {
          hosts = {
            for k, worker in module.worker: worker.name => null
          }
        }
      }
    }
  })
  filename = var.inventory_file
}
