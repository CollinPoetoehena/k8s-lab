TODO: here add development docs later, such as executing the full setup for the infrastructure, etc.

# Gettings Started
TODO: here how to start the system and download prerequisites, etc.

## Prerequisites
TODO: here add the things needed before running Ansible:
- [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) or a different Linux environment
- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Ansible](https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html)
- Azure Cloud environment to deploy the infrastructure

## Create Production Infrastructure
First, setup the environment using the automation script (this script provides automation (no manual steps of exporting login information, and security by adding them in your environment and not directly in the Git repository code, etc.)):
```sh
# You may need to remove the entire Azure CLI configuration before running to ensure a clean setup, without conflicts between different azure environments
rm -rf ~/.azure

# This script ensures the Terraform variables required are loaded into the current shell session, such as:
./scripts/infra/export_sensitive_tfvars.sh --ssh-key ~/.ssh/id_k8slab.pub
```

Then you can use Terraform to create the infrastructure:
```sh
# Navigate to infrastructure directory
cd terraform

# Initialize Terraform (download providers)
terraform init

# Preview what will be created
# NOTE: Replace the specific environment tfvars file (e.g., dta.tfvars) with your env (e.g., prod.tfvars)
terraform plan \
  -var-file="vars/common.tfvars" \
  -var-file="vars/dta.tfvars"

# Create the infrastructure without confirmation prompt (use with caution!)
terraform apply \
  -auto-approve \
  -var-file="vars/common.tfvars" \
  -var-file="vars/dta.tfvars"

# When done, destroy all resources. This executes without confirmation prompt (use with caution!)
terraform destroy \
  -auto-approve \
  -var-file="vars/common.tfvars" \
  -var-file="vars/dta.tfvars"
```