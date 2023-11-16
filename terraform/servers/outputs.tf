resource "local_file" "AnsibleInventory" {
  content = yamlencode({
    all = {
      hosts = {
        for node in module.node : node.name => {
          ansible_host = node.ipv4_address
          ipv6_address = node.ipv6_address
          rke2_type    = node.name == "master" ? "server" : "agent"
          rke2_server_options = node.name == "master" ? [
            "node-ip: ${node.ipv4_address}",
            "control-plane-resource-requests: kube-apiserver-memory=1000Mi",
            "node-taint: ${node.taints}"
          ] : null
          rke2_agent_options = node.name == "master" ? null : [
            "node-ip: ${node.ipv4_address}",
            "node-taint: ${node.taints}"
          ]
        }
      }
      children = {
        masters = {
          hosts = {
            for node in module.node :
            node.name => null
            if node.name == "master"
          }
        }
        workers = {
          hosts = {
            for node in module.node :
            node.name => null
            if node.name != "master"
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
