# Project Setup
## Requirements

### Install tooling:
* Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
* Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli

### Install Ansible modules
```bash
ansible-galaxy install -r requirements.yml
```

### Create `secrets.yml`
Create a `secrets.yml` in `inventories/{dev|prod}/group_vars/all/` and fill in the following values:
```yaml
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
# Random token used for communication between nodes on Kubernetes cluster setup
rke2_token: 
# Subdomain for the Jitsi server
jitsi_subdomain: 
# Email registered with the ACME SSL certificate server
cert_email: 
# Database root password
db_root_password: 
# ID of the database volume
postgres_volume_handle: 
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
