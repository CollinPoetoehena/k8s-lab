# =============================================================================
# MAIN - Resource Definitions and Module Orchestration
# =============================================================================
# This is the main entry point for the Terraform configuration.
# 
# Contains:
#   - Data sources (to query existing Azure resources): https://developer.hashicorp.com/terraform/tutorials/configuration-language/data-sources
#   - Resource blocks (to create infrastructure): https://developer.hashicorp.com/terraform/tutorials/configuration-language/resource
#   - Module calls (to organize code into reusable components): https://developer.hashicorp.com/terraform/language/modules
# Dependency order: Terraform automatically determines the order of resource creation based on references, such as using IDs from one resource in another.
# =============================================================================

// Data source to get information about the current Azure client (used for tenant ID)
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config
data "azurerm_client_config" "current" {}

// Data to retrieve existing Resource Group by name
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

// Random string for unique naming (e.g., Key Vault name must be globally unique)
// https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "unique" {
  length  = 13
  special = false
  upper   = false
}

# =============================================================================
# NETWORKING
# =============================================================================

module "network" {
  source = "git::https://github.com/CollinPoetoehena/terraform-azurerm-network.git?ref=v1.0.0"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  # Hub-and-spoke: hub VNet for shared services, spoke VNet for workloads
  # Local used as map key needs to be surrounded by () to be evaluated as an expression, otherwise it is treated as a literal string
  vnets = {
    (local.vnet_hub_name)   = { address_space = var.hub_cidr }
    (local.vnet_spoke_name) = { address_space = var.spoke_cidr }
  }

  # Peering is unidirectional in Azure — declare both directions for full connectivity.
  # Use remote_vnet_key to reference a VNet created by this module (ID resolved internally).
  # Use remote_vnet_id for VNets outside this module (e.g. in another resource group).
  peerings = {
    (local.peering_hub_to_spoke_name) = {
      vnet_key                = local.vnet_hub_name
      remote_vnet_key         = local.vnet_spoke_name
      allow_forwarded_traffic = true
    }
    (local.peering_spoke_to_hub_name) = {
      vnet_key                = local.vnet_spoke_name
      remote_vnet_key         = local.vnet_hub_name
      allow_forwarded_traffic = true
    }
  }

  nsgs = {
    # Hub NSG: allows SSH from anywhere into the jump host subnet
    (local.nsg_hub_name) = {
      security_rules = [local.nsg_security_rule_ssh_ingress]
    }
    # Spoke NSG: allows internal traffic from the hub address space only
    (local.nsg_spoke_name) = {
      security_rules = [local.nsg_security_rule_allow_from_hub]
    }
  }

  subnets = {
    (local.subnet_mgmt_name)    = { vnet_key = local.vnet_hub_name, address_prefix = var.mgmt_subnet_cidr }
    (local.subnet_tooling_name) = { vnet_key = local.vnet_spoke_name, address_prefix = var.tooling_subnet_cidr }
    (local.subnet_k8s_name)     = { vnet_key = local.vnet_spoke_name, address_prefix = var.k8s_subnet_cidr }
  }

  nsg_associations = {
    (local.subnet_mgmt_name)    = local.nsg_hub_name
    (local.subnet_tooling_name) = local.nsg_hub_name
    (local.subnet_k8s_name)     = local.nsg_spoke_name
  }
}

# =============================================================================
# COMPUTE
# =============================================================================
# Separate module call to avoid circular dependency: local.vms references
# module.network.subnet_ids, so VMs must be created after the network module.

module "compute" {
  source = "git::https://github.com/CollinPoetoehena/terraform-azurerm-compute.git?ref=v1.0.0"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags
  vms                 = local.vms
}

# =============================================================================
# OTHER RESOURCES
# =============================================================================

// Key Vault to store SSH public key and other secrets
// NOT necessary to create a separate module for this since it is just a simple and single resource
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault
resource "azurerm_key_vault" "main" {
  name                            = local.key_vault_name
  location                        = data.azurerm_resource_group.main.location
  resource_group_name             = data.azurerm_resource_group.main.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enabled_for_disk_encryption     = false

  # Soft delete is mandatory in Azure (cannot be fully disabled)
  # Set minimum retention period and disable purge protection for easier cleanup
  soft_delete_retention_days = 7     # Minimum allowed (7-90 days)
  purge_protection_enabled   = false # Allows immediate purge if you have permissions

  # Conditionally create access policy for user access
  # If user_object_id is empty, no access policy is created
  dynamic "access_policy" {
    # Creates 1 policy if user_object_id provided, 0 if empty
    for_each = var.user_object_id != "" ? [1] : []
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = var.user_object_id

      # Allow user to manage keys (create, read, update)
      key_permissions = [
        "Get",
        "List",
        "Create",
        "Update",
      ]

      # Allow user to manage secrets (CRUD operations)
      secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
      ]

      # Allow user to read certificates
      certificate_permissions = [
        "Get",
        "List",
      ]
    }
  }
}
