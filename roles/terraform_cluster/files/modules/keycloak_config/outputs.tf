output "clients" {
  value = {
    for key, value in local.clients : key => value.client_id
  }
}
