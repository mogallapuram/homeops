# 📚 Quick Reference Guide - K3s Cluster Terraform

## 🚀 Initial Deployment

```bash
# 1. Verify setup
chmod +x verify-setup.sh
./verify-setup.sh

# 2. Initialize Terraform with Consul backend
terraform init

# 3. Review planned changes
terraform plan

# 4. Deploy cluster
terraform apply

# 5. View outputs
terraform output
```

---

## 📊 Common Terraform Commands

### State Management
```bash
# List all resources
terraform state list

# Show specific resource
terraform state show proxmox_virtual_environment_vm.k3s_node[\"k3s-master-01\"]

# Pull state from Consul
terraform state pull

# Push state to Consul (rarely needed)
terraform state push
```

### Resource Operations
```bash
# Plan changes without applying
terraform plan

# Apply changes
terraform apply

# Destroy specific resource
terraform destroy -target=proxmox_virtual_environment_vm.k3s_node[\"k3s-worker-02\"]

# Destroy all resources (careful!)
terraform destroy
```

### Outputs
```bash
# Show all outputs
terraform output

# Show specific output
terraform output master_nodes
terraform output node_distribution
terraform output k3s_cluster_summary
```

---

## 🔄 State Locking

### Check Lock Status
```bash
# View Consul UI
http://10.10.10.15:8500/ui

# Check lock via API
curl http://10.10.10.15:8500/v1/kv/terraform/k3s-cluster/state
```

### Force Unlock (Emergency Only)
```bash
# Get lock ID from error message
terraform force-unlock <LOCK_ID>

# Example:
terraform force-unlock 1234567890abcdef
```

---

## 🔧 Maintenance Operations

### Update VM Configuration
```bash
# 1. Edit main.tf or terraform.tfvars
vim main.tf

# 2. Review changes
terraform plan

# 3. Apply changes
terraform apply
```

### Add New Worker Node
```bash
# 1. Add to main.tf k3s_nodes:
k3s-worker-03 = { 
  vm_id           = 8213
  memory          = 16384
  cores           = 4
  role            = "worker"
  longhorn_disk_gb = 300
}

# 2. Add IP in terraform.tfvars:
node_ipv4 = {
  # ... existing nodes ...
  k3s-worker-03 = "10.10.11.13/23"
}

# 3. Apply
terraform plan
terraform apply
```

### Modify Existing VM
```bash
# 1. Update memory/CPU in main.tf
k3s-worker-01 = { 
  vm_id           = 8211
  memory          = 32768  # Changed from 16384
  cores           = 8      # Changed from 4
  role            = "worker"
  longhorn_disk_gb = 300
}

# 2. Apply (VM will be recreated)
terraform apply
```

---

## 🐛 Troubleshooting

### Consul Connection Failed
```bash
# Check Consul status
docker ps | grep consul
docker logs consul-consul-1

# Test connectivity
curl http://10.10.10.15:8500/v1/status/leader

# Restart Consul (if needed)
docker restart consul-consul-1
```

### VM Creation Failed
```bash
# Check Proxmox permissions
ssh root@10.10.10.200 'pveum user permissions terraform@pve'

# Verify templates exist
ssh root@10.10.10.200 'qm list | grep 8000'
ssh root@10.10.10.201 'qm list | grep 8001'

# Check storage availability
ssh root@10.10.10.200 'pvesm status'
```

### State Locked
```bash
# If another user is running terraform
# Wait for them to finish

# If lock is stuck (last operation crashed)
terraform force-unlock <LOCK_ID>

# Verify unlock
terraform state list
```

### SSH Connection Issues
```bash
# Test SSH to VMs
ssh ram@10.10.11.1

# If failed, check cloud-init
ssh ram@10.10.11.1 'sudo cat /var/log/cloud-init.log'

# Verify key was injected
ssh ram@10.10.11.1 'cat ~/.ssh/authorized_keys'
```

---

## 📈 Scaling Operations

### Scale Up Worker Nodes
```bash
# Add more workers by editing main.tf
# Round-robin will distribute automatically

terraform plan
terraform apply
```

### Scale Down Worker Nodes
```bash
# 1. Remove from main.tf and terraform.tfvars

# 2. Apply changes
terraform apply

# VM will be destroyed
```

### Add Physical Node
```bash
# 1. Update main.tf:
proxmox_nodes = ["node1", "node2", "node3"]

node_templates = {
  node1 = 8000
  node2 = 8001
  node3 = 8002
}

# 2. Create template on node3
# 3. Update Proxmox permissions
# 4. Apply
terraform apply
```

---

## 🔐 Security

### Rotate API Token
```bash
# 1. Generate new token on Proxmox
ssh root@10.10.10.200 'pveum user token add terraform@pve tf2'

# 2. Update terraform.tfvars
pm_api_token = "terraform@pve!tf2=NEW-TOKEN-HERE"

# 3. Test
terraform plan

# 4. Delete old token
ssh root@10.10.10.200 'pveum user token delete terraform@pve tf'
```

### Backup State
```bash
# State is in Consul, but you can backup
terraform state pull > backup-$(date +%Y%m%d).tfstate

# Restore if needed (careful!)
terraform state push backup-20241229.tfstate
```

---

## 📊 Monitoring

### Check VM Status
```bash
# Via Terraform
terraform show

# Via Proxmox
ssh root@10.10.10.200 'qm list'
ssh root@10.10.10.201 'qm list'

# Via Proxmox UI
https://10.10.10.200:8006
```

### View Resource Details
```bash
# All VMs
terraform state list

# Specific VM
terraform state show proxmox_virtual_environment_vm.k3s_node[\"k3s-master-01\"]

# Distribution
terraform output node_distribution
```

---

## 🔗 Useful Links

- Proxmox UI: https://10.10.10.200:8006
- Consul UI: http://10.10.10.15:8500/ui
- Terraform Docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs
- K3s Docs: https://docs.k3s.io

---

## ⚡ Pro Tips

1. **Always run `terraform plan` first** - preview changes before applying
2. **Use workspaces** for different environments (dev/prod)
3. **Tag your VMs** - helps with organization and billing
4. **Keep templates synchronized** - automate with scripts
5. **Document changes** - git commit messages matter
6. **Use variables** - avoid hardcoding values
7. **Regular backups** - export state periodically
8. **Monitor Consul** - ensure state backend is healthy

---

**Quick Help:**
- Run `./verify-setup.sh` before starting
- Check README.md for detailed documentation
- Ask team members if stuck with state locks

**Emergency Contacts:**
- Infrastructure Lead: [Your Name]
- Proxmox Admin: [Admin Name]
- On-call: [On-call Contact]
