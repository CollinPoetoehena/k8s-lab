# ADR-TLS-001: Terraform for Infrastructure as Code

**Date:** 2026-02-06
**Status:** Accepted
**Deciders:** CollinPoetoehena

## Context and Problem Statement

The TransacFlow project requires a robust Infrastructure as Code (IaC) solution for provisioning and managing infrastructure resources such as virtual machines, networks, storage, load balancers, configurations, etc. The IaC tool should:
- Support multiple cloud providers to avoid vendor lock-in
- Enable declarative infrastructure definitions with version control
- Provide state management for tracking infrastructure changes
- Allow for modular, reusable infrastructure components
- Have strong community support and extensive provider ecosystem
- Integrate well with CI/CD pipelines for automated infrastructure deployments

## Decision

We will use **Terraform** as the primary Infrastructure as Code tool for provisioning and managing infrastructure resources in the TransacFlow project.

Terraform's HashiCorp Configuration Language (HCL) will be used for infrastructure definitions. State can optionally be stored in a remote backend (e.g., S3, Azure Blob Storage, or Terraform Cloud) for team collaboration and consistency.

## Consequences

**Positive:**
- **Cloud-Agnostic:** Works across AWS, Azure, GCP, and other providers, preventing vendor lock-in and enabling multi-cloud strategies
- **Large Community:** Extensive community support, abundant documentation, and numerous examples/modules available
- **Provider Ecosystem:** Broad provider support including cloud platforms, SaaS services, databases, monitoring tools, and Kubernetes resources
- **Declarative Approach:** Infrastructure defined in desired state, Terraform handles the execution plan
- **State Management:** Tracks infrastructure state, enabling drift detection and safe updates
- **Modular Design:** Supports reusable modules for standardizing infrastructure patterns
- **Plan Before Apply:** Preview changes before execution, reducing risk of unintended modifications
- **Integration:** Works well with CI/CD pipelines, Git workflows, and other DevOps tools
- **Mature Tooling:** Well-established with stable releases and comprehensive testing capabilities

**Negative:**
- **State File Management:** Requires careful management of state files, especially in team environments (mitigated by remote state backends)
- **Learning Curve:** HCL syntax and Terraform concepts require initial learning investment
- **Provider Lag:** Some cloud providers' new features may have delayed Terraform provider support
- **No Built-in Rollback:** Failed applies may leave infrastructure in partial state, requiring manual intervention
- **State Lock Contention:** Concurrent operations can cause state locking issues in team environments

**Neutral:**
- **HCL vs JSON/YAML:** HCL is Terraform-specific, but more expressive than pure JSON/YAML for infrastructure definitions
- **Open Source vs Enterprise:** Core is open source, but some advanced features (Sentinel policies, private registry) require Terraform Cloud/Enterprise
- **Imperative Operations:** Some complex scenarios may require provider-specific workarounds or multiple apply cycles

## Alternatives Considered

1. **Azure Bicep:** Microsoft's domain-specific language (DSL) for Azure resources. Rejected because it only supports Azure (vendor lock-in), limiting flexibility for multi-cloud or cloud migration scenarios. While it has excellent Azure integration, TransacFlow requires cloud-agnostic infrastructure tooling for potential future cloud provider changes.

2. **AWS CloudFormation:** AWS-native IaC service with deep AWS integration. Rejected for the same vendor lock-in concerns as Bicep. Limited to AWS ecosystem and uses verbose JSON/YAML syntax. Not suitable for multi-cloud infrastructure needs.

3. **Pulumi:** Modern IaC tool using general-purpose programming languages (Python, TypeScript, Go). While offering flexibility and familiar syntax for developers, it has a smaller community and ecosystem compared to Terraform. The additional abstraction layer and newer tooling introduce more complexity and potential risk for production infrastructure. Terraform's declarative HCL is more appropriate for infrastructure definitions.

4. **Ansible:** Primarily a configuration management tool, though it can provision infrastructure. While excellent for server configuration (and we use it for [Kubernetes setup/configuration](ADR-005-ConfigurationManagement.md)), Ansible lacks proper state management for infrastructure resources and is less suited for cloud resource provisioning compared to Terraform. Better used in combination with Terraform.

5. **Crossplane:** Kubernetes-native infrastructure management extending Kubernetes API. Rejected because it requires a Kubernetes cluster to manage infrastructure (chicken-and-egg problem for bootstrapping), adds significant complexity, and has a smaller ecosystem. Not appropriate when infrastructure provisioning needs to happen before Kubernetes cluster creation.

6. **OpenTofu:** Open-source Terraform fork created after HashiCorp's license change. While maintaining API compatibility with Terraform, it's relatively new with uncertain long-term support and smaller community. Terraform's established ecosystem and industry adoption make it the safer choice for production infrastructure at this time.

## Related Decisions

- [ADR-PLT-001: Kubernetes for Microservices Deployment and Orchestration](../infra/platform/ADR-PLT-001-K8s_General_Usage.md)
- [ADR-TLS-002: Ansible for Configuration Management](ADR-TLS-002-ConfigurationManagement.md)

## References

- [Terraform Official Documentation](https://www.terraform.io/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [HashiCorp Learn Terraform](https://learn.hashicorp.com/terraform)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Bicep Official Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/index.html)
- [Pulumi Official Documentation](https://www.pulumi.com/docs/)
- [Crossplane Official Documentation](https://crossplane.io/docs/)
- [OpenTofu Official Documentation](https://opentofu.org/docs/)
