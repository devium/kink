resource "local_file" "AnsibleHosts" {
  content = templatefile("hosts.yml.tmpl",
    {
      domain = var.domain,
      db = module.db.private_address,
      collab = module.collab.private_ip,
      auth = module.auth.private_ip,
      matrix = module.matrix.private_ip
    }
  )
  filename = "../ansible/group_vars/all/hosts.yml"
}
