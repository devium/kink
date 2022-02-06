# Project Setup
## Requirements

### Install tooling:
* Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
* Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli
* AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Install Ansible modules
```bash
ansible-galaxy install -r requirements.yml
```

### Configure AWS CLI
Get AWS key/secret from https://console.aws.amazon.com/iamv2/home#/users and configure the AWS CLI:
```bash
aws configure
```

### Get Hetzner API key
Create a new project on Hetzner Cloud and generate an API token for it. Save that token for `secrets.yml`.

### Create `secrets.yml`
Create a `secrets.yml` in `environments/{dev|prod}/group_vars/all/` and fill in the following values:
```yaml
project_name:
hcloud_token:
ssh_key:
domain:
```

## Deployment
Set the Ansible environment:
```bash
export ANSIBLE_ENV={dev|prod}
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
