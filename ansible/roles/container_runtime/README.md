# Container Runtime Role

Installs and configures the container runtime (containerd or CRI-O) required for Kubernetes on both control plane and worker nodes.

## Description

Kubernetes requires a container runtime to run containers. This role installs and configures the Container Runtime Interface (CRI) compatible runtime, ensuring proper integration with kubelet.

## Responsibilities

- **Runtime Installation**: Install containerd or CRI-O based on configuration
- **CRI Configuration**: Configure Container Runtime Interface settings
- **Cgroup Management**: Configure cgroup driver (systemd is recommended)
- **Container Registries**: Configure access to container registries (Docker Hub, Azure ACR, etc.)
- **Systemd Integration**: Set up systemd service files and enable runtime
- **Kernel Modules**: Load required kernel modules (overlay, br_netfilter)
- **Runtime Optimization**: Configure runtime settings for performance and resource limits
- **Security Context**: Configure runtime security settings (seccomp, AppArmor)
- **Image Pulling**: Configure image pull policies and credentials