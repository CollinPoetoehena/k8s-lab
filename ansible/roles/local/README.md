# Local Role

Sets up the local development environment on the developer's own machine, providing a lightweight Kubernetes cluster for fast iteration and testing without requiring any cloud infrastructure.

This role is intentionally minimal — the goal is fast feedback, not production fidelity.

## Description

The local environment uses [kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) to run a Kubernetes cluster entirely inside Docker containers on `localhost`. This avoids the need for VMs or cloud resources, making setup fast and self-contained. This role is only ever run against `localhost` using `ansible_connection=local` — no SSH or remote infrastructure required.

See the [Environments design doc](../../../../docs/design/Environments.md) for the reasoning behind the local environment and how it relates to DTA and Production.

## Responsibilities

- **Docker**: Ensure Docker is installed and running (prerequisite for kind)
- **kind**: Install kind and create a local Kubernetes cluster
- **kubectl**: Install the Kubernetes CLI and configure kubeconfig for the local cluster
- **helm**: Install the Helm package manager
- **Cluster validation**: Verify the cluster is healthy and reachable after setup