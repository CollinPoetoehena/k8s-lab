// Terraform vars for PRD specific

// Network configs (different CIDR than DTA)
hub_cidr = "10.30.0.0/16"
spoke_cidr = "10.40.0.0/16"
mgmt_subnet_cidr = "10.30.1.0/24"
k8s_subnet_cidr = "10.40.1.0/24"
tooling_subnet_cidr = "10.40.2.0/24"

// VM configs — counts and sizes only
// Node names and the full VM map are generated in locals.tf
worker_count     = 3
worker_disk_size = 128

tags = {
  environment = "prd"
}