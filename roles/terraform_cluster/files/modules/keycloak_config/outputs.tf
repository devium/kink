output "clients" {
  value = {
    jitsi     = keycloak_openid_client.jitsi.client_id
    nextcloud = keycloak_openid_client.nextcloud.client_id
    hedgedoc  = keycloak_openid_client.hedgedoc.client_id
    synapse   = keycloak_openid_client.synapse.client_id
  }
}
