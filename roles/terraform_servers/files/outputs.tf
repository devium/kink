resource "local_file" "AnsibleInventory" {
  content = yamlencode({
    all = {
      hosts = merge(
        {
          (module.master.name) = {
            ansible_host = module.master.ipv4_address
            ipv6_address = module.master.ipv6_address
            rke2_type = "server"
          }
        },
        {
          for k, worker in concat(module.worker): worker.name => {
            ansible_host = worker.ipv4_address
            ipv6_address = worker.ipv6_address
            rke2_type = "agent"
          }
        }
      )
      vars = {
        floating_ip = {
          ipv4_address = module.network.floating_ipv4
          ipv6_address = module.network.floating_ipv6
        }
        network_id = module.network.network_id
      }
      children = {
        masters = {
          hosts = {
            (module.master.name) = null
          }
        }
        workers = {
          hosts = {
            for k, worker in module.worker: worker.name => null
          }
        }
        k8s_cluster = {
          children = {
            masters = null
            workers = null
          }
        }
      }
    }
  })
  filename = var.inventory_file
}
