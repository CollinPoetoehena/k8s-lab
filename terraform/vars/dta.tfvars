// Terraform vars for DTA specific

// Network configs
hub_cidr = "10.10.0.0/16"
spoke_cidr = "10.20.0.0/16"
mgmt_subnet_cidr = "10.10.1.0/24"
k8s_subnet_cidr = "10.20.1.0/24"
tooling_subnet_cidr = "10.20.2.0/24"

// VM configs — counts and sizes only
// Node names and the full VM map are generated in locals.tf
worker_count   = 2
worker_disk_size = 64

tags = {
  environment = "dta"
}