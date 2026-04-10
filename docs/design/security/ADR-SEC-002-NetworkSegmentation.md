# ADR-SEC-002: Network Segmentation

**Date:** 2026-02-19
**Status:** Accepted
**Deciders:** CollinPoetoehena

## Context and Problem Statement

The system's infrastructure runs on Azure with a private Kubernetes cluster and a jump host for administrative access (see [ADR-SEC-001](ADR-SEC-001-JumpHost.md)). Without network segmentation, all VMs and cluster nodes would be on a flat network, allowing any compromised component to reach any other resource. The network design should:
- Isolate workloads into logical network segments with controlled traffic flows between them
- Ensure Kubernetes nodes (control plane and workers) are not reachable from the public internet
- Restrict administrative (SSH) access to only go through the jump host
- Apply principle of least privilege at the network layer via firewall rules
- Be defined as Infrastructure as Code (Terraform) for reproducibility and version control
- Keep the design simple enough for a learning project while reflecting real-world security practices

## Decision

We will use a **Hub-and-Spoke network topology** on Azure, with dedicated network zones for traffic separation: a **DMZ** (Demilitarized Zone) for internet-facing services, a **Management DMZ** for administrative access, and a private zone for the internal Kubernetes workloads.

### Hub-and-Spoke Topology Overview

The **Hub VNet** acts as the central network transit and security point. **Spoke VNets** host specific workloads and connect back to the Hub via VNet Peering. This pattern centralises shared services (routing, firewalling, management tooling) in the Hub while keeping workloads isolated in their own Spoke networks.

```
                        Internet
                           │
                    ┌──────▼───────┐
                    │     DMZ      │  (API Gateway, Load Balancer)
                    │  (Hub VNet)  │
                    └──────┬───────┘
                           │ VNet Peering
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌─────▼───────┐
   │  MGMT DMZ   │  │  K8s Spoke  │  │  (Future    │
   │  Jump Host  │  │  (Workers + │  │   Spokes)   │
   │             │  │    Control  │  │             │
   └─────────────┘  │   Plane)    │  └─────────────┘
                    └─────────────┘
```

### Network Zones

| Zone | Type | Purpose | Public IP |
|---|---|---|---|
| **DMZ** | Hub subnet | Internet-facing entry point (API Gateway, Load Balancer) | Yes |
| **MGMT DMZ**  | Hub subnet | Administrative access via Jump Host | Yes (SSH only to jump host) |
| **K8s Control Plane** | Spoke subnet | Kubernetes control plane nodes | No |
| **K8s Workers** | Spoke subnet | Kubernetes worker nodes and application pods | No |

### IP Address Layout (Example)
This is just an example, specific subnets might vary:
```
Hub VNet:          172.16.0.0/16
├── DMZ subnet:    172.16.0.0/24   → API Gateway / Load Balancer
└── MGMT DMZ subnet:  172.16.1.0/24   → Jump Host VM

K8s Spoke VNet:    172.17.0.0/16
├── k8s-control:   172.17.0.0/24   → Kubernetes Control Plane nodes
└── k8s-workers:   172.17.1.0/24   → Kubernetes Worker nodes
```

### Traffic Rules (NSGs)

| Zone | Inbound Allowed | Outbound Allowed |
|---|---|---|
| DMZ | HTTPS (443) from internet; HTTP (80) redirects | gRPC/REST to K8s Spoke services |
| MGMT DMZ (Jump Host) | SSH (22) from authorised operator IPs only | SSH to K8s Spoke (control + workers) |
| k8s-control | SSH from MGMT DMZ only; K8s API (6443) from workers | All internal; HTTPS outbound |
| k8s-workers | SSH from MGMT DMZ only; ephemeral ports from control | All internal; HTTPS outbound |

### DMZ vs. MGMT DMZ

- **DMZ (Demilitarized Zone):** Hosts internet-facing services such as the API Gateway and Load Balancer. Traffic here originates from external users/CLI clients. Strictly limited to application ports (HTTPS/443); no administrative access.
- **MGMT DMZ (Management DMZ / Beheer DMZ):** Dedicated zone for infrastructure management. Hosts the Jump Host VM. Accepts SSH only from known operator IP addresses. Provides the only SSH path into the private K8s Spoke network. Completely isolated from the application DMZ.

### Current Terraform Implementation

The Terraform configuration provisions the Hub VNet with subnets using the `vnet` module and controls traffic with the `nsg` module. The current setup provisions the management (MGMT DMZ) subnet with the jump host VM and its NSG, with security rules for SSH (port 22). The DMZ subnet and K8s Spoke VNet with its subnets are provisioned as the cluster is built out, all within the defined address spaces.

## Consequences

**Positive:**
- **Defence in Depth:** Multiple layers of network control (subnet isolation + NSG rules) mean a compromise of one segment does not automatically expose others
- **Least Privilege Networking:** NSG rules explicitly allow only the traffic needed for each subnet's function; all other traffic is implicitly denied
- **No Public Exposure of Cluster Nodes:** Kubernetes control plane and worker nodes have no public IPs; they are unreachable from the internet by default
- **Centralised Access Control:** Administrative SSH access is funnelled through the managed subnet (jump host), making access control and audit straightforward
- **Scalability:** The `/16` VNet address space provides ample room to add subnets for future components (e.g., monitoring, database, additional node pools)
- **Infrastructure as Code:** VNet, subnets, and NSGs are all defined in Terraform modules (`vnet`, `nsg`), ensuring the network configuration is versioned, reproducible, and auditable
- **Cost Effective:** VNets and subnets are free in Azure; NSGs are free; only the public IP and jump host VM incur cost

**Negative:**
- **Complexity vs. Flat Network:** Subnetting and NSG rule management adds configuration overhead compared to a flat, unprotected network (acceptable trade-off for security)
- **NSG Rule Management:** As the system grows, NSG rules can become complex; requires documentation and careful ordering of priority rules
- **No VNet Peering Required (Single VNet):** The Hub-and-Spoke model uses VNet Peering between the Hub VNet and K8s Spoke VNet; this is a standard, well-understood pattern but adds configuration overhead compared to a flat single-VNet approach

**Neutral:**
- **Hub-and-Spoke Scalability:** Additional spoke VNets (e.g., staging, monitoring, data) can be peered to the Hub without disrupting existing topology; the pattern scales naturally
- **NSG vs Azure Firewall:** NSGs provide subnet-level L4 (TCP/UDP) filtering. Azure Firewall (deployable in the Hub) provides L7 filtering and centralised policy management, but at significantly higher cost. NSGs are sufficient for this project's threat model.
- **Private DNS:** Internal name resolution between the Hub and Spoke VNets uses Azure's built-in private DNS; no additional configuration required within peered VNets.

## Alternatives Considered

1. **Single VNet with Subnets Only (No Hub-and-Spoke):** Placing all resources in one flat VNet with subnets instead of Hub-and-Spoke with VNet Peering. Simpler to set up but does not provide workload isolation at the VNet boundary level, makes it harder to apply centralised routing and firewall policies, and does not scale well when adding new workload environments (staging, monitoring).

2. **Multiple Isolated VNets without Peering:** Separate VNets for management and workloads with no connectivity between them. Rejected because it makes it impossible for the jump host (MGMT DMZ) to reach the Kubernetes nodes (K8s Spoke) for administration.

3. **Flat Network (Single Subnet, No Segmentation):** All VMs on one subnet with no NSG or zone differentiation. Rejected because it violates least-privilege networking; a compromised worker node could directly reach the jump host or API Gateway.

4. **Azure Firewall in Hub:** Centralised L7 firewall deployed in the Hub VNet to inspect all inter-spoke and internet traffic. Rejected because Azure Firewall is expensive (fixed hourly cost regardless of traffic) and its advanced features (FQDN filtering, threat intelligence) are not needed at this project's scale. NSGs at each subnet provide adequate L4 filtering.

5. **Kubernetes Network Policies Only:** Relying entirely on Kubernetes Network Policies (Calico, Cilium) without Azure-level VNet/NSG segmentation. Rejected because Kubernetes Network Policies operate at the pod layer and do not protect the underlying VM network or prevent VM-level lateral movement between zones.

6. **Private Endpoints / Azure Private Link:** For locking down access to Azure PaaS services (e.g., Key Vault, Neon). Not the primary focus of this ADR but can be added incrementally to prevent PaaS services from being accessible over the public internet.

## Related Decisions

- [ADR-SEC-001: Jump Host for Secure Infrastructure Access](ADR-SEC-001-JumpHost.md)
- [ADR-PLT-001: Kubernetes for Microservices Deployment and Orchestration](../infra/platform/ADR-PLT-001-K8s_General_Usage.md)
- [ADR-IaC-004: Terraform for Infrastructure as Code](../tools/ADR-004-IaC.md)

## References

- [Azure Virtual Networks Overview](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Azure Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure VNet Peering](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Azure Subnets](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-subnet)
- [Network Segmentation Best Practices (Microsoft)](https://learn.microsoft.com/en-us/azure/security/fundamentals/network-best-practices)
- [NIST SP 800-125B: Network Security for Virtualization](https://csrc.nist.gov/publications/detail/sp/800-125b/final)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
