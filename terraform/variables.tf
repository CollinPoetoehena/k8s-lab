# =============================================================================
# VARIABLES - User Inputs
# https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables
# =============================================================================
# Variables are INPUTS to your Terraform configuration - values that users provide.
# 
# Ways to provide variable values (in order of precedence):
#   1. CLI flags: terraform apply -var="vm_name=myvm"
#   2. terraform.tfvars file (most common for user inputs)
#   3. Environment variables: export TF_VAR_vm_name=myvm
#   4. Default value (used if no other value is provided)
#   5. Interactive prompt (if no default and no value provided)
#
# Use variables for: Anything a user should configure (SSH key, location, etc.)
# =============================================================================

// ============================================================================
// Authentication variables for Azure resource provider & General config variables
// NOTE: these variables exactly match what is set in /scripts/infra/export_sensitive_tfvars.sh
// ============================================================================
variable "subscription_id" {
  description = "Azure subscription ID where resources will be deployed"
  type        = string
  # No default - subscription must be explicitly specified
  # Get it via: az account show --query id -o tsv
}

// Required for creation of the resources in the specified resource group
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  # No default - this is a REQUIRED input
}

// Required for access to the VM using SSH
variable "ssh_public_key" {
  description = "SSH Public Key to use for VM access."
  type        = string
  sensitive   = true
  # No default - this is a REQUIRED input
}

variable "user_object_id" {
  description = "Object ID of the user for Key Vault access (leave empty to skip access policy)."
  type        = string
  default     = ""
}

variable "location" {
  description = "Location for all resources."
  type        = string
  # No default - this is a REQUIRED input
}

// ============================================================================
// Kubernetes cluster node configuration
// VMs are constants and generated from these variables in locals.tf, no need
// to repeat the full VM map in each environment tfvars file, just the counts and sizes
// ============================================================================
variable "admin_username" {
  description = "Admin username for all VMs."
  type        = string
}

variable "mgmt_vm_size" {
  description = "Azure VM size for management nodes (e.g. jump host and tooling-vm, etc.)."
  type        = string
}

variable "mgmt_vm_disksize" {
  description = "OS disk size in GB for management nodes (e.g. jump host and tooling-vm, etc.)."
  type        = number
}

variable "control_plane_count" {
  description = "Number of Kubernetes control plane nodes."
  type        = number
}

variable "worker_count" {
  description = "Number of Kubernetes worker nodes."
  type        = number
}

variable "control_plane_vm_size" {
  description = "Azure VM size for control plane nodes."
  type        = string
}

variable "worker_vm_size" {
  description = "Azure VM size for worker nodes."
  type        = string
}

variable "control_plane_disk_size" {
  description = "OS disk size in GB for control plane nodes."
  type        = number
}

variable "worker_disk_size" {
  description = "OS disk size in GB for worker nodes."
  type        = number
}

// ============================================================================
// Infrastructure topology variables
// ============================================================================
variable "hub_cidr" {
  description = "CIDR block for the hub VNet address space, e.g. 10.0.0.0/16."
  type        = string
}

variable "spoke_cidr" {
  description = "CIDR block for the spoke VNet address space, e.g. 10.1.0.0/16."
  type        = string
}

// Subnets
variable "mgmt_subnet_cidr" {
  description = "CIDR block for the management subnet in the hub VNet."
  type        = string
}
variable "k8s_subnet_cidr" {
  description = "CIDR block for the Kubernetes subnet"
  type       = string
}
variable "tooling_subnet_cidr" {
  description = "CIDR block for the tooling subnet"
  type       = string
}

variable "vm_image" {
  description = "Azure VM image reference (publisher, offer, sku, version)."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
