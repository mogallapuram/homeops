terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.70.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pm_api_url           # e.g. "https://10.10.10.200:8006/api2/json"
  api_token = var.pm_api_token         # e.g. "terraform@pve!tf=<SECRET>"
  insecure  = true                     # set false if you use valid SSL cert
}
