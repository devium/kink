resource "local_file" "AnsibleHosts" {
  content = templatefile("hosts.yml.tmpl",
    {
      domain = var.domain,
      db = module.db.private_address,
      collab = module.collab.private_ip,
      auth = module.auth.private_ip,
      matrix = module.matrix.private_ip
      bucket_name = module.s3.bucket_name
    }
  )
  filename = "../ansible/environments/${var.suffix}/group_vars/all/hosts.yml"
}

resource "local_file" "S3AccessKey" {
  content = templatefile("s3.yml.tmpl",
    {
      id = module.s3.access_key_id,
      secret = module.s3.access_key_secret
    }
  )
  filename = "s3.${var.suffix}.yml"
}
