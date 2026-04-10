# Management VM Role

Configures the management VM that serves as the operational control center for the infrastructure. This role installs all necessary management tools, automation software, and utilities required to manage the Kubernetes cluster and Azure resources.

## Description

The management VM contains all operational tooling for infrastructure and application management. It is accessed through the jump host (bastion) and provides administrators with a complete management environment for the Kubernetes cluster.

## Responsibilities

- **Kubernetes Tooling**: Install kubectl, kubeadm, and helm for cluster management
- **Ansible Automation**: Install Ansible and required Python packages for ongoing automation
- **Cloud CLI Tools**: Install Azure CLI for Azure resource management
- **kubeconfig Setup**: Configure kubectl access to the Kubernetes cluster
- **Monitoring Tools**: Install monitoring and observability clients (optional)
- **SSH Configuration**: Configure SSH for accessing cluster nodes via jump host
- **Package Management**: Ensure all management dependencies are installed