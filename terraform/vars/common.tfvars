// Variable Values for all environments: https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files

// VM image: This is the same for all environments
// TODO: Add ADR for OS choice (currently RHEL 9)
vm_image = {
  publisher = "RedHat"
  offer     = "RHEL"
  sku       = "94_gen2"
  version   = "latest"
}

// Username for all VMs: This is the same for all environments
admin_username = "azureuser"

// ================================================================================================================
// VM SIZES & SPECIFICATIONS
// Note that most playgrounds/experimental environments are limited by vCPUs. Therefore, optimization should be for
// the highest available RAM per vCPU to allow as many VMs to be created as possible within the vCPU limits.
// For example, Pluralsight Cloud playground allows max 10 vCPUs for Azure VMs, and other environments likely have similar limits
// ================================================================================================================
// Mgmt and control-plane VMs optimized for only 1vCPU with highest possible RAM 
// within policy limits to create as many as possible for these
// Standard_B1ms: vCPUs:1, RAM:2GiB, Data disks:2, Max IOPS:640
mgmt_vm_size = "Standard_B1ms"
// Minimum is 64 GiB (otherwise will cause error: specified disk size 32 GB is smaller than the size of the corresponding disk in the VM image: 64 GB)
mgmt_vm_disksize = 64
control_plane_vm_size = "Standard_B1ms"
control_plane_count   = 2 // 2 is enough to have a HA pair, the rest can be optimized for worker nodes for actual workloads
control_plane_disk_size = 64

// Worker VM optimized for RAM and IOPS (this has the highest RAM/vCPU ratio of available VMs within policy: 4 RAM per vCPU), 
// since these workers require more RAM to run the workloads, such as monitoring stack, etc.
// Standard_D2s_v5: vCPUs:1, RAM:8GiB, Data disks:4, Max IOPS:3750
worker_vm_size = "Standard_D2s_v5"