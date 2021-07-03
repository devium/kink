# Ansible inventory file
resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
    {
      db = module.db.db_private_address,
      collab = module.deploy.collab_private_ip
    }
  )
  filename = "../ansible/inventory"
}
