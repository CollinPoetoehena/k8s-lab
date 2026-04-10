# ADR-PLT-002: Kubernetes Setup using Kubeadm and Ansible

**Date:** 2026-04-10
**Status:** Accepted
**Deciders:** CollinPoetoehena

## Context and Problem Statement

The applications that use this k8s-lab project require a production-grade (and DTA for reliability purposes, allowing to validate in a production-like setup with similar setup) Kubernetes cluster for hosting microservices. The production setup should:
- Provide full control over cluster configuration and component versions
- Enable deep customization of networking, storage, and security policies
- Avoid cloud provider vendor lock-in and abstractions
- Maintain infrastructure as code with repeatable, automated provisioning
- Use standard Kubernetes tooling to ensure portability and industry-standard practices
- Allow for detailed monitoring and troubleshooting at the infrastructure level
- Provide consistency between development/test and production environments
- Support high availability and scalability for production workloads
- To a lesser extent facilitate learning and understanding of Kubernetes internals (since this is a personal project) 

## Decision

We will deploy the production Kubernetes cluster using **Kubeadm** for cluster bootstrapping on individual VMs, combined with **Ansible** for automated configuration management and provisioning.

This approach provides complete control over the Kubernetes control plane and worker nodes while leveraging Ansible's declarative infrastructure-as-code capabilities to ensure reproducible, automated cluster deployment and configuration.

## Consequences

**Positive:**
- **Full Control:** Complete control over Kubernetes version, component configuration, upgrade timing, and cluster architecture decisions
- **Deep Customization:** Ability to customize networking (CNI plugins), storage classes, security policies, and resource allocation without managed service constraints
- **Infrastructure as Code:** Ansible playbooks provide version-controlled, repeatable, and auditable infrastructure provisioning and configuration
- **Standard Kubernetes:** Uses upstream Kubeadm, ensuring alignment with official Kubernetes documentation and best practices
- **Vendor Independence:** No cloud provider lock-in; cluster can be migrated across cloud providers or on-premises infrastructure with minimal changes
- **Cost Optimization:** Potential cost savings by avoiding managed service premiums and paying only for compute/storage resources
- **Troubleshooting Capability:** Direct access to all cluster components enables deep troubleshooting and performance optimization
- **Environment Consistency:** Same tooling DTA and production environments (similar tooling in Local environment, but not the exact same) ensures consistency across all stages of development lifecycle
- **Security Control:** Full control over security hardening, network policies, and compliance requirements without provider-imposed limitations
- **Automation Foundation:** Ansible playbooks serve as living documentation and can be extended for day-2 operations (upgrades, scaling, backup, etc.)

**Negative:**
- **Operational Responsibility:** Full responsibility for cluster availability, security patches, upgrades, and disaster recovery
- **Expertise Requirements:** Requires deep Kubernetes knowledge for troubleshooting, scaling, and maintaining cluster health
- **Manual Upgrade Management:** Cluster upgrades must be planned, tested, and executed manually (though automated via Ansible)
- **No Managed Add-ons:** Features like automatic backups, integrated monitoring dashboards, and one-click upgrades available in managed services must be implemented separately
- **Initial Setup Complexity:** More complex initial setup compared to managed services that provide clusters in minutes
- **Maintenance Burden:** Ongoing maintenance tasks (certificate rotation, etcd management, control plane updates) require active management

**Neutral:**
- **High Availability:** HA control plane configuration requires multiple master nodes and load balancing setup (can be automated with Ansible)
- **Monitoring Stack:** Need to deploy separate monitoring solutions (Prometheus, Grafana) rather than relying on cloud provider dashboards
- **Time Investment:** Higher upfront time investment for setup and automation development, but pays dividends in long-term flexibility and learning

## Alternatives Considered

1. **Managed Kubernetes Services (AKS, EKS, GKE):** Cloud provider managed Kubernetes services handle control plane management, automated upgrades, and integrated monitoring. While operationally simpler, they introduce vendor lock-in, limit customization options (CNI choices, control plane configuration), impose managed service costs, and abstract away infrastructure details. For a project prioritizing flexibility and infrastructure control (and to a lesser extend learning), these trade-offs are significant.

2. **Rancher/RKE:** Kubernetes distribution with management UI and additional tooling. Adds an abstraction layer on top of Kubernetes with proprietary management components, creating potential lock-in to Rancher ecosystem. Also adds complexity with additional components to manage and maintain.

3. **Red Hat OpenShift (also called OpenShift Container Platform (OCP)):** Enterprise Kubernetes platform with additional developer and operational tools. While feature-rich, it's expensive, and introduces OpenShift-specific concepts that diverge from vanilla Kubernetes. Overkill for this project's requirements.

4. **Kubespray:** Ansible-based Kubernetes deployment tool similar to our approach. While comprehensive, it's opinionated with pre-configured playbooks that may be harder to customize. Using Kubeadm directly with custom Ansible playbooks provides more transparency and control over exact cluster configuration.

5. **kops:** Kubernetes Operations tool primarily for AWS with some GCP/OpenStack support. Cloud-specific orientation limits portability, and the tool abstracts infrastructure management in ways that reduce control compared to direct Kubeadm + Ansible approach.

6. **Kubernetes Managed by Third-Party (DigitalOcean, Linode, etc.):** Similar drawbacks to major cloud providers' managed services but with smaller ecosystems, fewer integrations, and potentially less stability/support.

## Related Decisions

- [ADR-PLT-001: Environment Strategy](./ADR-PLT-001-Environments.md)
- [ADR-TLS-002: Ansible for Configuration Management](../tools/ADR-TLS-002-ConfigurationManagement.md)

## References

- [Kubeadm Official Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Ansible Documentation](https://docs.ansible.com/)
- [Kubernetes Production Best Practices](https://kubernetes.io/docs/setup/best-practices/)
- [Creating Highly Available Clusters with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
- [Kubeadm Cluster Configuration](https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
