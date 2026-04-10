# ADR-SEC-001: Jump Host (Bastion) for Secure Infrastructure Access

**Date:** 2026-04-10
**Status:** Accepted
**Deciders:** CollinPoetoehena

## Context and Problem Statement

The system's infrastructure runs on Azure with a private Kubernetes cluster inside a dedicated Virtual Network (VNet). Direct SSH or `kubectl` access to cluster nodes from the internet would expose the infrastructure to attack. A controlled, auditable access mechanism is required that:
- Prevents direct public internet access to Kubernetes nodes and control plane
- Provides a single, hardened entry point for administrative and operational access
- Enables SSH-based access to internal cluster nodes and VMs
- Logs and audits all access for compliance and incident investigation
- Minimises the attack surface of infrastructure access paths
- Integrates with Terraform (provisioning) and Ansible (configuration) workflows

## Decision

We will use a **Jump Host (Bastion Host)** as the sole secure entry point for administrative access to the private infrastructure network.

The jump host is a minimal, hardened Azure VM placed in a dedicated management subnet with a public IP. All SSH access to internal Kubernetes nodes, control plane VMs, and other private resources must go through the jump host via SSH agent forwarding. No other VMs in the cluster network have public IPs.

```
Operator  ──SSH──▶  Jump Host (public IP)  ──SSH forward──▶  Kubernetes Nodes / VMs (private IPs)
```

The jump host is provisioned via Terraform and configured via the Ansible `jump_host` role, which handles SSH hardening, firewall rules, access logging, and minimal package installation.

## Consequences

**Positive:**
- **Reduced Attack Surface:** Only the jump host is publicly reachable; all other VMs and Kubernetes nodes have private IPs only, drastically reducing exposure to internet-based attacks
- **Single Choke Point:** All administrative access flows through one host, making it easy to enforce access controls, monitor sessions, and revoke access centrally
- **Audit Logging:** All SSH connections through the jump host are logged (session metadata, source IPs, timestamps), providing a full audit trail for compliance and incident response
- **SSH Agent Forwarding:** Operators connect to internal nodes using their local SSH keys forwarded through the jump host; private keys never leave the operator's machine
- **Minimal Attack Surface on Host:** The jump host runs only SSH and essential system utilities; no application workloads, databases, or unnecessary services are installed
- **Firewall Rules:** Strict inbound rules allow only SSH (port 22) from authorised IP ranges; all other inbound traffic is blocked at the network security group (NSG) level
- **Infrastructure as Code:** The jump host is fully provisioned by Terraform and configured by Ansible, ensuring reproducibility, version control, and automated recovery
- **Cost Effective:** A small, low-cost VM is sufficient as the jump host performs no compute-intensive work

**Negative:**
- **Single Point of Failure:** If the jump host becomes unavailable, administrative access to the cluster is blocked; mitigated by having recovery procedures and Terraform-based reprovisioning
- **Additional SSH Hop:** All access requires an extra SSH hop through the jump host, adding minor latency and connection complexity
- **Key Management:** SSH key management must be handled carefully; lost or compromised keys require immediate revocation and rotation
- **Operational Overhead:** Operators must configure SSH agent forwarding and jump host proxying in their SSH config; requires initial setup documentation

**Neutral:**
- **Not a Bastion Service:** Azure Bastion (PaaS) is an alternative but is not used here in favour of a self-managed approach for learning and portability; see Alternatives Considered
- **Management Subnet:** The jump host resides in a dedicated management subnet, separated from the Kubernetes node subnet and application workload network via VNet segmentation (see ADR-SEC-002)
- **Ansible Configuration:** The `jump_host` Ansible role handles all post-provisioning setup: SSH hardening (`sshd_config`), firewall (`ufw`/`iptables`), access logging, and package minimisation, etc.

## Alternatives Considered

1. **Azure Bastion (PaaS):** Microsoft's managed bastion service providing browser-based SSH/RDP access without a public IP on target VMs. Rejected because it incurs higher cost (hourly pricing regardless of usage), introduces vendor lock-in to Azure-specific access mechanisms, and provides less flexibility for scripted/automated access patterns needed for Ansible-based configuration management.

2. **VPN (Virtual Private Network):** Providing operators with VPN access to the private VNet, enabling direct access to all internal resources. Rejected due to the additional operational complexity of VPN server setup, certificate management, and client configuration. A jump host achieves the same network access control with simpler tooling.

3. **Direct Public IPs on Nodes:** Assigning public IP addresses to Kubernetes nodes and restricting access via NSG rules. Firmly rejected because it exposes each node's IP directly to the internet, significantly expanding the attack surface even with firewall rules. A single, hardened entry point is a fundamental security principle.

4. **Kubernetes API Server Public Endpoint:** Exposing the Kubernetes API server publicly with IP allowlisting for `kubectl` access. Rejected because it exposes the control plane directly to the internet. The jump host approach keeps the API server on a private IP and routes `kubectl` traffic through the SSH tunnel.

5. **Zero Trust / Identity-Aware Proxy (e.g., Cloudflare Access, Google BeyondCorp):** Modern zero-trust access solutions that authenticate users at the identity layer rather than network layer. While superior in large organisations, these solutions add significant complexity and cost for a personal learning project. The jump host is appropriate for the current scale and objectives.

## Related Decisions

- [ADR-SEC-002: Network Segmentation](ADR-SEC-002-NetworkSegmentation.md)
- [ADR-PLT-003: Production & DTA Environment](../infra/platform/ADR-PLT-003-Production-DTA.md)
- [ADR-IaC-004: Terraform for Infrastructure as Code](../tools/ADR-004-IaC.md)
- [ADR-005: Ansible for Configuration Management](../tools/ADR-005-ConfigurationManagement.md)

## References

- [Bastion Host Pattern](https://en.wikipedia.org/wiki/Bastion_host)
- [SSH Agent Forwarding](https://www.ssh.com/academy/ssh/agent)
- [SSH ProxyJump Configuration](https://www.ssh.com/academy/ssh/proxyjump)
- [Azure Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [CIS Benchmarks for SSH](https://www.cisecurity.org/benchmark/distribution_independent_linux)
- [NIST SP 800-123: Guide to General Server Security](https://csrc.nist.gov/publications/detail/sp/800-123/final)
