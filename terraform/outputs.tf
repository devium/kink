output "hosts" {
  value = {
    master = {
      ipv4_address = module.master.ipv4_address
      ipv6_address = module.master.ipv6_address
    }
    workers = [
      for worker in module.worker: {
        (worker.name) = {
          ipv4_address = worker.ipv4_address
          ipv6_address = worker.ipv6_address
        }
      }
    ]
    floating = {
      ipv4_address = module.network.floating_ipv4
      ipv6_address = module.network.floating_ipv6
    }
  }
}

resource "local_file" "AnsibleInventory" {
  content = yamlencode({
    all = {
      hosts = {
        for k, worker in concat([module.master], module.worker): worker.name => {
          ansible_host = worker.ipv4_address
        }
      }
      children = {
        workers = {
          for k, worker in module.worker: worker.name => null
        }
      }
    }
  })
  filename = "../ansible/environments/${var.environment_suffix}/inventory.yml"
}
