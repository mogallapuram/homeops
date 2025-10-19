# --- Proxmox provider inputs ---
variable "pm_api_url" {
  description = "Proxmox API endpoint, e.g. https://10.10.10.200:8006/api2/json"
  type        = string
}

variable "pm_api_token" {
  description = "Proxmox API token in format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "pm_node" {
  description = "Proxmox node name"
  type        = string
  default     = "node1"
}

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

# --- Template / VM defaults ---
variable "template_vmid" {
  description = "VMID of the cloud-init template to clone"
  type        = number
  default     = 8000
}

variable "root_disk_gb" {
  description = "Root disk size (GB) for all VMs"
  type        = number
  default     = 30
}

# --- Cloud-init user ---
variable "ci_user" {
  description = "Cloud-init username to create inside the VM"
  type        = string
  default     = "ram"
}

variable "ci_password" {
  description = "Optional password for the cloud-init user (not recommended)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key to inject"
  type        = string
  default     = "/root/.ssh/id_rsa.pub"
}

# --- Static IPs per node ---
variable "node_ipv4" {
  description = "Map of node name to IPv4 CIDR (e.g., 10.10.11.1/23)"
  type        = map(string)
}

variable "ipv4_gateway" {
  description = "Default IPv4 gateway"
  type        = string
  default     = "10.10.10.1"
}
