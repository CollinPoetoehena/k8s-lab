# ADR-TLS-002: Ansible for Configuration Management

**Date:** 2026-02-06
**Status:** Accepted
**Deciders:** CollinPoetoehena

## Context and Problem Statement

The TransacFlow project requires a configuration management solution for automating the setup and maintenance of infrastructure after provisioning. The configuration management tool should:
- Automate installation and configuration of software packages and services
- Manage system configurations consistently across multiple servers
- Enable repeatable, version-controlled infrastructure configuration
- Support Kubernetes cluster bootstrapping and ongoing maintenance tasks
- Be easy to use and maintain with minimal operational overhead
- Have broad platform support (Linux, cloud providers, network devices)
- Integrate well with existing IaC tools (Terraform) and CI/CD pipelines
- Provide idempotent operations to ensure desired state

## Decision

We will use **Ansible** as the configuration management tool for automating infrastructure configuration, software installation, and ongoing maintenance tasks in the TransacFlow project.

Ansible playbooks will be written in YAML to define configuration tasks, with inventory files managing target hosts. Ansible will be used primarily for Kubernetes cluster setup and configuration using Kubeadm, system hardening, and application deployment automation.

## Consequences

**Positive:**
- **Agentless Architecture:** SSH-based communication requires no agents on target machines, reducing maintenance overhead and security concerns
- **Low Learning Curve:** YAML-based playbooks are easy to read and write, making it accessible for team members with varying DevOps experience
- **Idempotent Operations:** Built-in idempotency ensures tasks can be run multiple times safely without unintended side effects
- **Large Community:** Extensive ecosystem with thousands of community modules, active forums, and abundant documentation
- **Comprehensive Module Library:** A lot of modules covering system administration, cloud providers, networking, databases, and Kubernetes management
- **Simple Setup:** Requires only Python on target machines (typically pre-installed) and Ansible on control node
- **Integration:** Works seamlessly with Terraform outputs, Git workflows, and CI/CD pipelines (Jenkins, GitLab CI, GitHub Actions, etc.)
- **Push-Based Model:** Control node initiates tasks, providing better visibility and control over when changes occur
- **Flexibility:** Supports both procedural tasks (playbooks) and declarative configurations (roles)
- **Testing Support:** Molecule framework enables testing of Ansible roles and playbooks

**Negative:**
- **Performance at Scale:** Sequential execution and SSH overhead can be slow for large-scale deployments (mitigated with parallelism configuration)
- **Python Dependency:** Requires Python on target machines, though this is rarely an issue with modern Linux distributions
- **Limited Windows Support:** While improving, Windows support is less mature than Linux support
- **Error Handling:** Error handling and debugging can be challenging compared to general-purpose programming languages
- **State Management:** No built-in state tracking like Terraform; relies on idempotency and target system state

**Neutral:**
- **Push vs Pull:** Push-based model requires control node accessibility, unlike pull-based tools (Puppet, Chef) that agents initiate
- **Variable Precedence:** Multiple variable sources (inventory, group_vars, host_vars, playbook) can create complexity in variable management
- **Ansible Galaxy:** Community roles vary in quality and maintenance status; requires careful vetting before use

## Alternatives Considered

1. **Chef:** Powerful configuration management tool using Ruby DSL. Rejected because it requires agents on all managed nodes (Chef Client), has a steeper learning curve with Ruby-based recipes, and introduces additional operational complexity. The agent-based architecture adds maintenance overhead that Ansible's agentless approach avoids.

2. **Puppet:** Mature configuration management tool with declarative language. Rejected due to agent requirement (Puppet Agent), complex proprietary DSL that's harder to learn than YAML, and the need for a central Puppet Master server. While excellent for large enterprises, it's overly complex for TransacFlow's requirements.

3. **SaltStack:** Fast configuration management with event-driven architecture. While performant, it requires agents (Salt Minions) on target nodes and has a smaller community compared to Ansible. The additional complexity of master-minion architecture and ZeroMQ communication is unnecessary for our use case.

4. **Terraform + Cloud-Init:** Using Terraform with cloud-init scripts for initial configuration. While suitable for basic bootstrapping, cloud-init lacks the robust configuration management capabilities, idempotency guarantees, and maintainability of dedicated tools. Not appropriate for ongoing configuration management and complex multi-step setups like Kubernetes clusters.

5. **Shell Scripts:** Traditional bash/shell scripting for configuration. Rejected because scripts lack idempotency, structure, and reusability. Error handling is complex, testing is difficult, and maintenance becomes problematic as scripts grow. Ansible provides all these features out of the box.

6. **CFEngine:** Lightweight configuration management tool with autonomous agents. While efficient, it has a much smaller community, fewer modules, and a steeper learning curve compared to Ansible. The limited ecosystem and resources make it less suitable for a project requiring extensive community support.

## Related Decisions

- [ADR-PLT-001: Kubernetes for Microservices Deployment and Orchestration](../infra/platform/ADR-PLT-001-K8s_General_Usage.md)
- [ADR-TLS-001: Terraform for Infrastructure as Code](ADR-TLS-001-IaC.md)

## References

- [Ansible Official Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Molecule Testing Framework](https://molecule.readthedocs.io/)
- [Ansible for Kubernetes](https://www.ansible.com/integrations/containers/kubernetes)
- [Kubeadm Ansible Playbooks](https://github.com/kubernetes-sigs/kubespray)
- [Ansible Lint](https://ansible-lint.readthedocs.io/)
