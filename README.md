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
Use an existing vault or create a `secrets.{dev|prod}.yml` in `vault/`. Define all `vault_` values referenced at the top of `inventories/common/main.yml`.

You can use `scripts/bip39_secrets.sh` to generate BIP39-like secrets.

Use `scripts/synapse_signing_key.py` to generate a Synapse signing key (requires `signedjson`).

Encrypt the secrets file you just created using Ansible:
```
ansible-vault encrypt vault/secrets.{dev|prod}.yml
```

Note: All files in `vault/` should be encrypted using `ansible-vault`. Decrypted secrets temporarily appear during deployment in the `secrets/` directory.

## Deployment
Set the Ansible stage:
```bash
export ANSIBLE_STAGE={dev|prod}
```
Make sure the SSH keys can be found by Ansible:
```bash
ssh-add <path-to-ssh-key>
```
From now on, use `--ask-vault-pass` on all Ansible commands or store the vault password in `secrets/.vault_pass.txt`. See https://docs.ansible.com/ansible/latest/vault_guide/vault_using_encrypted_content.html for more info.

Run the Ansible playbook:
```bash
ansible-playbook site.yml --ask-vault-pass --ask-become-pass --tags all,reboot
```
The `--ask-become-pass` is required for local Docker containers to generate complex secrets. You can skip this if you can run Docker without sudo or already have your secret files ready.

Setting up the cluster initially requires a full node reboot after updating the networking backend in the `cluster.yml` playbook. This can be avoided on future runs by skipping the `reboot` tag.

## Teardown
Run the Ansible playbook with the `terraform-destroy` tag:
```bash
ansible-playbook webservers.yml --tags terraform-destroy
```
Terraform states for `network`, `cluster`, and `apps` will now be invalid. Make sure to clear them manually, e.g., by deleting and recreating the workspaces on Terraform Cloud. `config` states should be persisted via volumes and database.

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
