terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.70.0"
    }
  }

  # Consul backend for remote state storage with locking
  backend "consul" {
    address = "10.10.10.150:8500"
    scheme  = "http"
    path    = "terraform/k3s-cluster/state"
    
    # State locking to prevent concurrent modifications
    lock = true
    
    # Optional: Add credentials if Consul ACL is enabled
    # access_token = var.consul_token
  }
}

provider "proxmox" {
  endpoint  = var.pm_api_url
  api_token = var.pm_api_token
  insecure  = true
  
  # Optional: Configure SSH for node operations
  ssh {
    agent = true
  }
}
