# --- Proxmox API Configuration ---
variable "pm_api_url" {
  description = "Proxmox API endpoint (can be any node in cluster)"
  type        = string
}

variable "pm_api_token" {
  description = "Proxmox API token in format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

# --- Proxmox Storage Configuration ---
variable "pm_datastore" {
  description = "Proxmox datastore/storage ID (e.g., local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "bridge" {
  description = "Bridge interface to attach NICs to"
  type        = string
  default     = "vmbr0"
}

# --- VM Disk Configuration ---
variable "root_disk_gb" {
  description = "Root disk size (GB) for all VMs"
  type        = number
  default     = 30
}

# --- Cloud-init Configuration ---
variable "ci_user" {
  description = "Cloud-init username to create inside the VM"
  type        = string
  default     = "ram"
}

variable "ci_password" {
  description = "Optional password for cloud-init user (not recommended, use SSH keys)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key to inject via cloud-init"
  type        = string
  default     = "keys/public-key.pub"
}

# --- Network Configuration ---
variable "node_ipv4" {
  description = "Map of VM name to IPv4 CIDR (e.g., 10.10.11.1/23)"
  type        = map(string)
}

variable "ipv4_gateway" {
  description = "Default IPv4 gateway"
  type        = string
  default     = "10.10.10.1"
}

# --- Optional: Consul Configuration (if ACL enabled) ---
variable "consul_token" {
  description = "Consul ACL token for state backend (optional)"
  type        = string
  default     = ""
  sensitive   = true
}
