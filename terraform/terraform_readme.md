# 🏡 HomeOps Terraform — Automated Proxmox VM Deployment

This repository automates VM provisioning on **Proxmox VE** using **Terraform** with reusable variable-driven configurations.  
It is part of the `homeops` project for building and maintaining a self-hosted K3s cluster and supporting infrastructure.

---

## 🚀 Overview

Terraform automates the lifecycle of virtual machines cloned from a **Proxmox Cloud-Init template** (VMID 8000).  
Each VM is configured with SSH access, static IPs, CPU, memory, and tags for tracking.

### Key Features
- Full clone from Cloud-Init template
- Automatic static IP assignment
- Dynamic VM naming (via variable map)
- Role-based API access with Proxmox token
- SSH key injection through Cloud-Init

---

## ⚙️ Required Setup

### 1. Proxmox User & Role Configuration

Create the `TerraformRole` and token on your Proxmox host:

```bash
# Create role with required privileges
pveum role add TerraformRole -privs "VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.Memory VM.Config.Network VM.Config.Options VM.Config.Cloudinit VM.Console VM.Monitor VM.PowerMgmt Datastore.Allocate Datastore.AllocateSpace Datastore.Audit SDN.Use Pool.Allocate Sys.Audit Sys.Console VM.GuestAgent.Audit"

# Create user
pveum user add terraform@pve --comment "Terraform Automation User"

# Add API token
pveum user token add terraform@pve tf --comment "Terraform API token"

# Assign role permissions
pveum acl modify / -user terraform@pve -role TerraformRole
pveum acl modify /vms/8000 -user terraform@pve -role TerraformRole
pveum acl modify /storage/local-lvm -user terraform@pve -role TerraformRole
```

---

## 🧩 File Structure

```
homeops/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── keys/
│   │   ├── public-key.pub
│   └── README.md
```

---

## 📦 Variables Explained

| Variable | Description | Example |
|-----------|--------------|----------|
| `pm_api_url` | Proxmox API endpoint | `"https://10.10.10.200:8006/api2/json"` |
| `pm_user` | Proxmox user with privileges | `"terraform@pve"` |
| `pm_token_id` | Proxmox token ID | `"tf"` |
| `pm_token_secret` | Secret token string | `"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"` |
| `template_id` | Template VMID for Cloud-Init | `8000` |
| `storage` | Storage backend (datastore) | `"local-lvm"` |
| `vm_settings` | Map of VM names and IPs | `{ vkm1 = "10.10.11.1/23", vkm2 = "10.10.11.2/23" }` |
| `gateway` | Default network gateway | `"10.10.10.1"` |
| `ssh_public_key_path` | Path to SSH public key | `"./keys/public-key.pub"` |
| `ci_user` | Default user for Cloud-Init | `"ram"` |

---

## 🛠️ Running Terraform

Initialize and apply configuration:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Check created VMs on Proxmox UI or via CLI:

```bash
qm list
```

---

## 🧠 Tips

- Always ensure **Cloud-Init** is configured in your Proxmox template (`ide2` attached, `template: 1`).
- To use another storage backend (e.g., `nfs-storage`), update `storage` in `terraform.tfvars`.
- If cloning fails with 403 errors, ensure your `TerraformRole` has `VM.Clone`, `VM.Config.Cloudinit`, and `SDN.Use` privileges.

---

## 🧾 Output Example

After successful apply:

```
Outputs:

vm_ids = {
  "vkm1" = 8101
  "vkm2" = 8102
}
vm_ips = {
  "vkm1" = "10.10.11.1/23"
  "vkm2" = "10.10.11.2/23"
}
```

---

## 🧑‍💻 Maintainer

**Author:** Ramakrishna Mogallapu  
**Project:** HomeOps Infrastructure Automation  
**Environment:** Proxmox VE 9.0.x + Terraform  
**Last Updated:** 2025-10-19  
**License:** MIT

---

Enjoy your automated homelab! ☁️💡
