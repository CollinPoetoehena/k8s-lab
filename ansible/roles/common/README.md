# Common Role

Base configuration role applied to all nodes in the infrastructure.

## Description

This role provides foundational system configuration that every node requires, regardless of its specific function. It ensures consistent baseline security, networking, and system settings across the entire infrastructure.

## Responsibilities

- **Package Management**: Install essential system packages (curl, wget, vim, git, etc.)
- **User Management**: Create service accounts and configure sudo access
- **SSH Configuration**: Harden SSH daemon settings and manage authorized keys
- **System Updates**: Apply security patches and system updates
- **Logging Configuration**: Set up rsyslog or journald with appropriate retention
- **Kernel Parameters**: Configure sysctl settings (e.g., disable swap for Kubernetes)
- **Hostname Configuration**: Set proper hostname and update /etc/hosts
- **Monitoring Agents**: Install node_exporter for Prometheus monitoring (optional)
- **Etc...**: Any other common configuration tasks that apply to all nodes