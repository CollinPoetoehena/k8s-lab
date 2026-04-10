#!/bin/bash
# =============================================================================
# Generate terraform.tfvars
# =============================================================================
# Generates a terraform.tfvars file in the Terraform root directory with
# values retrieved from your Azure environment and a local SSH public key.
# Terraform automatically loads terraform.tfvars when running plan/apply.
#
# Prerequisites:
#   - Azure CLI installed and authenticated (az login)
#   - SSH key pair already generated at the path passed via --ssh-key
#
# Usage:
#   ./scripts/infra/export_sensitive_tfvars.sh --ssh-key ~/.ssh/id_k8slab.pub
#   ./scripts/infra/export_sensitive_tfvars.sh --ssh-key ~/.ssh/id_k8slab.pub --resource-group my-rg
#
# Design:
#   - File exporting: This script exports a file with the generated variables that Terraform reads
#   - Alternative (this was used earlier): load script via "source" or "eval" commands, however, this was aborted
#       because it caused issues with shell session persistence and error handling. For example, the "log" functions like
#       log_info write to stdout, which can interfere with "eval" or "source" when trying to capture variable output, 
#       and also caused issues with error handling (e.g. if a command failed, it could exit the entire shell session 
#       (e.g. tab completion caused it to crash before) because the "set -e" is loaded in the shell session by sourcing this script.)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../load_config.sh"

# show_usage prints usage information
show_usage() {
    echo "Usage: $0 --ssh-key PATH [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  --ssh-key PATH           Path to SSH public key (e.g. ~/.ssh/id_k8slab.pub)"
    echo ""
    echo "Options:"
    echo "  --resource-group NAME    Azure resource group name (default: first available)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --ssh-key ~/.ssh/id_k8slab.pub"
    echo "  $0 --ssh-key ~/.ssh/id_k8slab.pub --resource-group my-rg"
}

SSH_KEY_PATH=""
RESOURCE_GROUP=""

## Parse command line arguments
# Each 'shift 2' advances the positional parameters by two (while the number of args ($#) is greater than 0), 
# effectively consuming the option and its value, so the next option becomes $1 in the next iteration:
#   - 'shift 2' removes $1 and $2 from the argument list (the option and its value),
#     so $3 becomes the new $1, $4 becomes $2, etc.
#   - This ensures that after handling an option and its value, the next unprocessed argument is always $1.
#   - Internally, 'shift' modifies the shell's argument list ($@ and $*) by discarding the specified number of leading arguments.
#   - Example: If the script is called with '--image foo --version 1.0', after processing '--image foo' and 'shift 2',
#     the next $1 is '--version' and $2 is '1.0'.
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssh-key) SSH_KEY_PATH="$2"; shift 2 ;;
        --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
        -h|--help) show_usage; exit 0 ;;
        *) log_error "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

if [ -z "$SSH_KEY_PATH" ]; then
    log_error "--ssh-key is required"
    show_usage
    exit 1
fi

log_header_1 "Terraform tfvars Generator"

# Check if Azure CLI is installed
log_info "Checking prerequisites..."
if ! command -v az &> /dev/null; then
    log_error "Azure CLI is not installed. Please install it first:"
    echo "  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
log_success "Azure CLI found"

# Check if logged in to Azure
log_info "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    log_error "Not logged in to Azure. Running 'az login'..."
    # Use device code login for better compatibility in scripts and CI environments
    az login --use-device-code
fi
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
log_success "Logged in to Azure (Subscription: $SUBSCRIPTION_NAME)"

# Get resource group — use provided value or fall back to the first one in the subscription
log_info "Getting resource group..."
if [ -z "$RESOURCE_GROUP" ]; then
    RESOURCE_GROUP=$(az group list --query "[0].name" -o tsv 2>/dev/null)
    if [ -z "$RESOURCE_GROUP" ]; then
        log_error "No resource groups found. Create one first, or pass --resource-group."
        exit 1
    fi
    log_info "Found resource group, using: $RESOURCE_GROUP"
fi

# Get location from resource group
LOCATION=$(az group show --name "$RESOURCE_GROUP" --query location -o tsv)
log_success "Using location: $LOCATION"

# Load SSH public key
log_info "Getting SSH public key..."
if [ ! -f "$SSH_KEY_PATH" ]; then
    log_error "SSH public key not found at: $SSH_KEY_PATH"
    echo "Generate a key pair with:"
    echo "  ssh-keygen -t rsa -b 4096 -f \"${SSH_KEY_PATH%.pub}\" -C \"azure-k8slab\""
    exit 1
fi
SSH_PUBLIC_KEY=$(cat "$SSH_KEY_PATH")
log_success "SSH public key loaded from: $SSH_KEY_PATH"

# Get user object ID (used for Key Vault access policies)
log_info "Getting Azure AD user object ID..."
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null)
if [ -n "$USER_OBJECT_ID" ]; then
    log_success "User object ID: $USER_OBJECT_ID"
else
    log_info "Could not retrieve user object ID — skipping (optional, used for Key Vault access)"
fi

# Write terraform.tfvars to the Terraform root directory.
# Terraform automatically loads this file when running plan/apply — no extra flags needed.
# See: https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files
TFVARS_FILE="$TERRAFORM_DIR/terraform.tfvars"
log_info "Writing $TFVARS_FILE..."

cat > "$TFVARS_FILE" <<EOF
# Auto-generated by $0 — do not edit manually
# Re-run the script to refresh these values
subscription_id      = "$SUBSCRIPTION_ID"
resource_group_name  = "$RESOURCE_GROUP"
location             = "$LOCATION"
ssh_public_key       = "$SSH_PUBLIC_KEY"
user_object_id       = "$USER_OBJECT_ID"
EOF

log_success "terraform.tfvars written to: $TFVARS_FILE"

echo ""
log_success "Done!"
echo ""
echo "Next steps:"
echo "  1. cd $TERRAFORM_DIR"
echo "  2. Execute Terraform commands, such as \"terraform plan\" or \"terraform apply\", which will automatically load the generated terraform.tfvars"
echo ""
log_info "Note: terraform.tfvars contains sensitive values — it is gitignored."
