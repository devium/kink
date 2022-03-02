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

### Create `secrets.yml`
Create a `secrets.yml` in `inventories/{dev|prod}/group_vars/all/` and fill in the following values:
```yaml
# Project name used in user-facing applications
project_name: 
# SSH key name as defined in Hetzner Cloud
ssh_key: 
# Fully qualified domain name of the desired root domain
domain: 
# Hetzner Cloud project API token
hcloud_token: 
# Hetzner DNS API token
hdns_token: 
# Hetzner DNS zone ID of the desired hosted zone (check URL in DNS console)
hdns_zone_id: 
# ID of the database volume
postgres_volume_handle: 
nextcloud_volume_handle: 
# Subdomain for servers/apps
subdomains:
  jitsi: 
  jitsi_keycloak: 
  keycloak: 
  nextcloud: 
  homer: 
  hedgedoc: 
  element: 
  matrix: 
# Email registered with the ACME SSL certificate server
cert_email: 
# Google SSO client ID and secret
google_identity_provider_client_id: 
google_identity_provider_client_secret: 
# Container image used for Homer dashboard assets and configuration
homer_assets_image: 

# Random tokens and passwords that may be generated

# Token used for communication between nodes on Kubernetes cluster setup
rke2_token: <generate>
# Database user passwords
db_passwords:
  root: <generate>
  keycloak: <generate>
  hedgedoc: <generate>
  nextcloud: <generate>
keycloak_admin_password: <generate>
# Keycloak confidential client secrets
keycloak_secrets:
  jitsi: <generate>
  nextcloud: <generate>
  hedgedoc: <generate>
jitsi_jwt_secret: <generate>
hedgedoc_secret: <generate>
nextcloud_admin_password: <generate>
```

## Deployment
Set the Ansible stage:
```bash
export ANSIBLE_STAGE={dev|prod}
```
Run the Ansible playbook:
```bash
ansible-playbook main.yml
```

## Teardown
Run the Ansible playbook with the `terraform-destroy` tag:
```bash
ansible-playbook main.yml --tags terraform-destroy
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
