# =============================================================================
# LOCALS - Computed Values
# https://developer.hashicorp.com/terraform/tutorials/configuration-language/locals
# =============================================================================
# Locals are COMPUTED values - they transform or combine variables.
# Users CANNOT set these directly - they are for internal logic only.
#
# Reference locals as: local.name (e.g., local.public_ip_name)
# Reference variables as: var.name (e.g., var.vm_name)
#
# Use locals for:
#   - Derived values (computed from variables)
#   - Constants (internal defaults)
#   - Complex expressions (to avoid repetition - DRY principle)
#   - Conditional logic with fallback values
# =============================================================================

# Locals that apply for all, not environment-specific
# This differs from common.tfvars which contains variables that can be overridden per environment, such as location,
# but this locals.tf file is really for reusable logic that is not environment-specific, such as naming conventions, derived values, etc.
locals {
  // Reusable unique prefix for all resources to ensure uniqueness and avoid naming conflicts
  unique_str = random_string.unique.result

  // Reusable variables (e.g. prefixes, naming conventions) that are used across multiple modules/resources:
  k8s_control_plane_prefix = "k8s-control-plane-"
  k8s_worker_prefix        = "k8s-worker-"
  key_vault_name           = "kv-${random_string.unique.result}"

  // Network resource naming — VNets & Peerings
  vnet_hub_name             = "vnet-hub-management" // Management VNet (Hub)
  vnet_spoke_name           = "vnet-spoke-internal" // Internal VNet (Spoke)
  peering_hub_to_spoke_name = "hub-to-spoke-peering"
  peering_spoke_to_hub_name = "spoke-to-hub-peering"

  // Network resource naming — Subnets
  subnet_mgmt_name    = "subnet-mgmt"    // Hub VNet
  subnet_tooling_name = "subnet-tooling" // Internal VNet
  subnet_k8s_name     = "subnet-k8s"     // Internal VNet

  // NSG naming
  nsg_hub_name   = "${local.vnet_hub_name}-nsg"
  nsg_spoke_name = "${local.vnet_spoke_name}-nsg"

  // Generate the VM map from count + size variables (instead of repeating in vars files)
  // Each node as an individual block in the per-environment tfvars
  // Produces: { "k8s-control-plane-1" => { size, nics, image, os_disk, ... }, ... }
  vms = merge(
    // Jump host — single VM, public-facing entry point for all SSH access (see ADR-SEC-001)
    // Jump host is static, this is the same for all environments, no need for this in vars files
    {
      "jump-host" = {
        size           = var.mgmt_vm_size
        admin_username = var.admin_username
        ssh_public_key = var.ssh_public_key
        nics = [
          {
            name             = "nic"
            subnet_id        = module.network.subnet_ids[local.subnet_tooling_name] // Hub VNet — only VM accessible from the internet (see ADR-SEC-001)
            assign_public_ip = true                                                 // Only VM with a public IP; all others are accessed through this jump host
          }
        ]
        image   = var.vm_image
        os_disk = { disk_size_gb = var.mgmt_vm_disksize }
      }
      // Management VM — same specs as jump host, private, access via jump host
      "mgmt-vm" = {
        size           = var.mgmt_vm_size
        admin_username = var.admin_username
        ssh_public_key = var.ssh_public_key
        nics = [ // TODO: does this one also need a mgmt-nic to be accessible by jump host??
          {
            name      = "nic"
            subnet_id = module.network.subnet_ids[local.subnet_mgmt_name] // Spoke VNet — access via jump host
          }
        ]
        image   = var.vm_image
        os_disk = { disk_size_gb = var.mgmt_vm_disksize }
      }
    },
    // Build control plane and worker node maps from count + size variables in vars files, instead of hardcoding each VM in vars files
    // This avoids having to put all of this in variables.tf, and allows for easy scaling with different sizes and counts per environment
    // without repeating the full VM map in each tfvars file, just the counts and sizes.
    { for i in range(1, var.control_plane_count + 1) :
      "${local.k8s_control_plane_prefix}${i}" => {
        size           = var.control_plane_vm_size
        admin_username = var.admin_username
        ssh_public_key = var.ssh_public_key
        nics = [
          {
            name      = "nic"
            subnet_id = module.network.subnet_ids[local.subnet_k8s_name] // Control plane nodes are private; access via jump host
          }
        ]
        image   = var.vm_image
        os_disk = { disk_size_gb = var.control_plane_disk_size }
      }
    },
    { for i in range(1, var.worker_count + 1) :
      "${local.k8s_worker_prefix}${i}" => {
        size           = var.worker_vm_size
        admin_username = var.admin_username
        ssh_public_key = var.ssh_public_key
        nics = [
          {
            name      = "nic"
            subnet_id = module.network.subnet_ids[local.subnet_k8s_name] // Worker nodes are private; access via jump host
          }
        ]
        image   = var.vm_image
        os_disk = { disk_size_gb = var.worker_disk_size }
      }
    }
  )

  // Reusable SSH access rule
  nsg_security_rule_ssh_ingress = {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow SSH access"
  }

  // Reusable HTTP access rule
  nsg_security_rule_http_ingress = {
    name                       = "API"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTP access for API/Web traffic"
  }

  // Reusable rule to allow from hub
  nsg_security_rule_allow_from_hub = {
    name                       = "allow-from-hub"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.hub_cidr // Allow from hub VNet CIDR only
    destination_address_prefix = "*"
  }
}
