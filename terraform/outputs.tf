resource "local_file" "AnsibleHosts" {
  content = templatefile("hosts.yml.tmpl",
    {
      domain = var.domain,

      bucket_name = module.s3.bucket_name

      bastion_id = module.bastion.instance_id
      collab_id = module.collab.instance_id
      auth_id = module.auth.instance_id
      matrix_id = module.matrix.instance_id
      www_id = module.www.instance_id
      draw_id = module.draw.instance_id
      next_id = module.next.instance_id

      db_id = module.db.instance_id
    }
  )
  filename = "../ansible/environments/${var.suffix}/group_vars/all/hosts.yml"
}

resource "local_file" "S3AccessKey" {
  content = templatefile("s3.yml.tmpl",
    {
      id = module.s3.access_key_id
      secret = module.s3.access_key_secret
    }
  )
  filename = "s3.${var.suffix}.yml"
}
