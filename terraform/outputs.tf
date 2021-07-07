resource "local_file" "AnsibleHosts" {
  content = templatefile("hosts.yml.tmpl",
    {
      bastion = module.deploy.bastion_hostname,
      db = module.db.db_private_address,
      collab = module.deploy.collab_private_ip
    }
  )
  filename = "../ansible/group_vars/all/hosts.yml"
}
