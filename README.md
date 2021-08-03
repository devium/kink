# Project Setup

## Requirements
### Install & configure Terraform (Ubuntu)
https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started#install-terraform
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```
Login to Terraform Cloud:
```bash
terraform login
```
Prepare variable file:
```bash
touch {dev|prod}.tfvars
```
Fill in the following variables:
```ini
project_name = "PROJECT_NAME"
domain = "{dev|prod}.DOMAIN"
suffix = "{dev|prod}"
db_password = "DB_ROOT_PASSWORD"
```

### Install & configure Ansible
https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pip
```bash
pip install ansible
cd ansible
ansible-galaxy collection install -r requirements.yml
```
Create vault password file.
```bash
touch {dev|prod}.password
```
On a single line in the file enter the vault password.

### Install & configure AWS-CLI
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
Get AWS key/secret from https://console.aws.amazon.com/iamv2/home#/users and configure the AWS CLI:
```bash
aws configure
```

### Other requirements
Boto is used for AWS interaction using Ansible:
```bash
pip install boto3
```

### Add SSH keys
Configure your `~/.ssh/config` or manually add the SSH key each session. `ssh-add` is required for agent forwarding on the bastion host anyway.
```bash
ssh-add ~/.ssh/SOME_KEY.pem
```

## Terraform
```
terraform workspace select {dev|prod}
terraform apply -var-file {dev|prod}.tfvars
```
A sanity check will be performed at the beginning to ensure you're using the correct `.tfvars` file for the current workspace.

### Domain name servers
If your specified domain is not an SLD, make sure to create an NS record for you domain in your SLD's hosted zone, redirecting requests to your domain's nameservers.

Note: Domain record changes may take a few minutes to propagate.

### Tear down
```
terraform destroy
```
This destroys all EC2 and RDS instances, VPCs, S3 buckets, and domain records and hosted zones. This takes about 10 minutes to perform. A final snapshot is performed on the database.

Note: S3 buckets will only be destroyed if empty.

## Ansible

### Set environment
```bash
export ANSIBLE_ENV={dev|prod}
```

### Set S3 credentials
After running `terraform apply` copy the contents of `terraform/s3.{dev|prod}.yml` to the ansible vault:
```bash
ansible-vault edit ansible/environments/{dev|prod}/group_vars/all/vault
```

### Run entire Ansible playbook
Make sure you run `terraform apply` before this at least once to update your environment's `hosts.yml` and S3 credentials. This playbook uses EC2 instance IDs to query their private IP addresses.
```bash
ansible-playbook main.yml [--diff] --tags --limit localhost,bastion,auth --tags setup-all,start
# Wait for Keycloak to start.
ansible-playbook main.yml [--diff] --tags --limit localhost,auth --tags init-all
ansible-playbook main.yml [--diff] --tags --limit '!bastion,!auth' --tags setup-all,start
```

### Limitations
- Private server IP addresses are queried from AWS from `localhost`, so be sure to always include `localhost` in `--limit`.
- Running `ansible-playbook` with both `start` and `init-all` tasks will most likely fail as Keycloak takes a few minutes to start and won't be ready in time for the `init-keycloak` tasks.

### Update EC2 packages
```bash
ansible-playbook main.yml [--diff] --tags update
```

### Stop/start AWS EC2 and RDS instances
```bash
ansible-playbook main.yml [--diff] --tags stop-aws
ansible-playbook main.yml [--diff] --tags start-aws
```
Make sure to rerun `terraform apply` after since IP addresses have likely changed and domains need to be updated.

## Manual SSH via bastion jump server
```bash
ssh -A ec2-user@BASTION_DOMAIN
```
The Ansible playbook contains an `~/.ssh/config` file for hostnames in the private subnets:
```bash
ssh collab
ssh auth
ssh matrix
ssh www
ssh draw
```

## Database access
Connect to the bastion server and use the PostgreSQL client to connect to the database. A `.pg_service` file with the database address is provided:
```bash
psql service=db
```

## Log files
Depending on the service, log files can be accessed via `docker logs` or `journalctl`.
Docker logs (most services):
```bash
sudo docker logs [-f] CONTAINER_NAME
```
Systemd (Matrix-associated services):
```bash
sudo journalctl -u SERVICE_NAME.service
```
