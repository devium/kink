output "master" {
  value = {
    ipv4_address = module.master.ipv4_address
    ipv6_address = module.master.ipv6_address
  }
}

output "workers" {
  value = [
    for k, v in module.worker: 
    {
      ipv4_address = module.worker[k].ipv4_address
      ipv6_address = module.worker[k].ipv6_address
    }
  ]
}

output "network" {
  value = {
    id = module.network.network_id
    floating_ipv4 = module.network.floating_ipv4
    floating_ipv6 = module.network.floating_ipv6
  }
}
