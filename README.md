# Project Setup
## Requirements

### Install tooling:
* Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
* Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli

### Install Ansible modules
```bash
ansible-galaxy install -r requirements.yml
pip install kubernetes
```

### Manage secrets
Create a `secrets.{dev|prod}.yml` in `secrets/` and fill in the following values:
```yaml
# Email registered with the ACME SSL certificate server
cert_email: 
# Fully qualified domain name of the desired root domain
domain: 
# Google SSO client ID and secret
google_identity_provider_client_id: 
google_identity_provider_client_secret: 
# Hetzner Cloud project API token
hcloud_token: 
# Hetzner DNS API token
hdns_token: 
# Hetzner DNS zone ID of the desired hosted zone (check URL in DNS console)
hdns_zone_id: 
# Container image of the static website served at www
home_site_image: 
# Name of Minecraft players with admin privileges
minecraft_admins: 
# Link to zip file of Minecraft plugins
minecraft_modpack_url: 
# Minecraft world name
minecraft_world: 
# Project name used in user-facing applications
project_name: 
# SSH key name as defined in Hetzner Cloud
ssh_key: 
# Container image that contains WorkAdventure maps
workadventure_maps_image: 
# Workadventure map.json that is initially loaded
workadventure_start_map: 

# IDs of persistent Hetzner volumes
volume_handles:
  backup: 
  hedgedoc: 
  mailserver: 
  minecraft: 
  minecraft_backup: 
  minecraft_bedrock: 
  nextcloud: 
  postgres: 
  pretix: 
  synapse: 

# Subdomain for servers/apps
subdomains_override:
  jitsi: 
  jitsi_keycloak: 
  shlink: 
  shlink_web: 

# Random tokens and passwords that may be generated
hedgedoc_secret: <generate>
minecraft_rcon_password: <generate>
minecraft_rcon_web_password: <generate>
rke2_token: <generate>
mail_password: <generate>

admin_passwords:
  collabora: <generate>
  grafana: <generate>
  keycloak: <generate>
  nextcloud: <generate>

db_passwords:
  grafana: <generate>
  hedgedoc: <generate>
  keycloak: <generate>
  nextcloud: <generate>
  postgres: <generate>
  pretix: <generate>
  shlink: <generate>
  synapse: <generate>

jitsi_secrets:
  jicofo: <generate>
  jvb: <generate>
  jwt: <generate>

keycloak_secrets:
  grafana: <generate>
  hedgedoc: <generate>
  jitsi: <generate>
  nextcloud: <generate>
  synapse: <generate>

mail_accounts:
  - name: "{{ mail_account }}"
    password: "{{ mail_password }}"

synapse_secrets:
  registration: <generate>
  macaroon: <generate>
```
You can use `./generate-secrets.sh` to generate BIP39-like passwords for all variables set to `<generate>`.

## Deployment
Set the Ansible stage:
```bash
export ANSIBLE_STAGE={dev|prod}
```
Make sure the SSH keys can be found by Ansible:
```bash
ssh-add <path-to-ssh-key>
```
Run the Ansible playbook:
```bash
ansible-playbook site.yml
```

When creating a new cluster from scratch, you have to go slower:
```bash
ansible-playbook mail.yml
ansible-playbook webservers.yml
ansible-playbook setup.yml
ansible-playbook cluster.yml --extra-vars "{'terraform_cluster_targets': ['module.namespaces']}"
ansible-playbook cluster.yml --extra-vars "{'terraform_cluster_targets': ['module.rke2']}"
# The command above changes RKE2's networking backend. This requires a complete server restart.
ansible all -m reboot
ansible-playbook cluster.yml --extra-vars "{'terraform_cluster_targets': ['module.keycloak']}"
ansible-playbook cluster.yml
ansible-playbook config.yml
```

## Teardown
Run the Ansible playbook with the `terraform-destroy` tag:
```bash
ansible-playbook site.yml --tags terraform-destroy
```

## Additional information
### Volume management
Hetzner volume management with Kubernetes is a little fickle. In order to properly unmount a manually created volume do the following:
1. Check which node the volume is attached to in Hetzner Cloud.
2. Stop pods or uninstall Helm charts that access this volume.
3. Delete PVCs, volumeattachments, and PVs.
4. Check on node if the volume has been properly unmounted: `findmnt | grep csi` or `findmnt | grep HC_Volume`.
5. If not, unmount on the node using `umount MOUNTPATH`.
The volume mount can get screwed up. You will notice that the volume handle in `findmnt` is different from the one specified in the PV description.

### Resetting/reinitializing the database
Any changes to the Postgres volume will be lost while the pod is still running. At the same time, the volume is only attached while the pod is running. So in order to make persistent changes, you will have to mount the volume manually while the pod is inactive.

Uninstall the Postgres Helm chart using "helm uninstall -n postgres primary" and mount the volume using the Hetzner Cloud console. Use `findmnt | grep HC_Volume` to find the mount point and make any changes to the volume through that mount point.

If you want to reset the database, make sure to delete the `data` folder as well as the `.user_scripts_initialized` file on the same level. Don't do this in prod. Duh.

Unmount using `umount` or the Hetzer Cloud console, then reinstall the Helm chart using Ansible/Terraform.
