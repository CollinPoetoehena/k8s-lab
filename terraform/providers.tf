# =============================================================================
# PROVIDERS - Cloud Provider Configuration
# https://developer.hashicorp.com/terraform/tutorials/configuration-language/configure-providers
# =============================================================================
# Providers are plugins that enable Terraform to interact with cloud platforms,
# SaaS providers, and APIs (e.g., AWS, Azure, Google Cloud, Kubernetes).
#
# This file configures:
#   - Provider version requirements and sources
#   - Provider-specific features and behaviors
#   - Authentication methods
#
# TERRAFORM BLOCK:
#   Defines Terraform engine version and required providers.
#   Run `terraform init` to download providers to .terraform/ directory.
#
# PROVIDER BLOCKS:
#   Configure provider behavior (features, authentication, defaults).
#   Only define in ROOT module - child modules inherit configuration.
#
# AUTHENTICATION:
#   - azurerm: Uses Azure CLI by default (ensure: az login)
#   - random: No authentication needed (generates values locally)
# =============================================================================

terraform {
  // Specific version for Terraform
  required_version = ">= 1.0"

  required_providers {
    # Azure Resource Manager - for creating Azure infrastructure
    # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.58.0" # Exact version for production stability
    }

    # Random - for generating unique names, IDs, passwords
    # https://registry.terraform.io/providers/hashicorp/random/latest/docs
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6" # Allow patch updates (3.6.x)
    }
  }
}

# =============================================================================
# Azure Provider Configuration
# =============================================================================
provider "azurerm" {
  # Note: Provider uses Azure CLI authentication by default
  # Ensure you're logged in: az login
  # Check current subscription: az account show

  # Subscription ID from variable (set in terraform.tfvars)
  # Explicitely set subscription to avoid ambiguity if user has multiple subscriptions,
  # and avoid error: "subscription ID could not be determined and was not specified"
  subscription_id = var.subscription_id
  
  # Disable automatic resource provider registration (required for limited permissions)
  # Pluralsight sandbox and other restricted environments don't allow provider registration
  # Required providers should already be registered by the subscription admin
  resource_provider_registrations = "none"
  
  # Required features block configures provider behavior
  features {
    # Key Vault behavior
    key_vault {
      # Automatically purge soft-deleted vaults on destroy (vs 90-day retention)
      purge_soft_delete_on_destroy = true
      # Recover soft-deleted vaults instead of failing
      recover_soft_deleted_key_vaults = true
    }
  }
}