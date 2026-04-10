# =============================================================================
# OUTPUTS - Exported Values
# https://developer.hashicorp.com/terraform/tutorials/configuration-language/outputs
# =============================================================================
# Outputs expose values from your Terraform configuration after deployment.
#
# Purposes:
#   1. Display important information to users (hostnames, IPs, commands)
#   2. Pass values to other Terraform configurations (using remote state)
#   3. Use in automation scripts (via `terraform output` command)
#
# Access outputs:
#   - View all: terraform output
#   - Specific value: terraform output hostname
#   - JSON format: terraform output -json
#   - In scripts: terraform output -raw ssh_command
#
# Sensitive outputs are hidden by default but can be revealed with -json flag.
# =============================================================================

// ============================================================================
// Outputs for entire infrastructure (not already covered in modules)
// ============================================================================
output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

output "key_vault_name" {
  description = "Name of the Key Vault (globally unique)"
  value       = local.key_vault_name
}

// ============================================================================
// Module Outputs - Expose all outputs from each module
// If not mentioned here explicitely, the output is not present
// ============================================================================
output "network" {
  description = "All network module outputs (VNets, subnets, NSGs, peerings)"
  value       = module.network
}

output "compute" {
  description = "All compute module outputs (VMs, NICs, IPs)"
  value       = module.compute
}
