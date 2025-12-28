# 🚀 K3s Cluster Deployment on Proxmox with Terraform

Automated K3s cluster provisioning on **Proxmox VE 9** using **Terraform** with:
- **Round-robin distribution** across 2 physical nodes
- **Consul state management** for team collaboration
- **3 master nodes** (control plane HA)
- **2 worker nodes** (with Longhorn storage)
- **Non-shared storage** support (local-lvm)

---

## 📋 Architecture Overview

### Cluster Topology

```
┌─────────────────────────────────────────────────────────┐
│                   K3s Cluster (HA)                      │
├─────────────────────────────────────────────────────────┤
│  Masters: 3 nodes (control plane + etcd)                │
│  Workers: 2 nodes (workload + Longhorn storage)         │
└─────────────────────────────────────────────────────────┘

Physical Distribution (Round-Robin):
┌──────────────────────┬──────────────────────┐
│      node1           │       node2          │
│  (10.10.10.200)      │   (10.10.10.201)     │
├──────────────────────┼──────────────────────┤
│ k3s-master-01 (8201) │ k3s-master-02 (8202) │
│ k3s-master-03 (8203) │ k3s-worker-01 (8211) │
│ k3s-worker-02 (8212) │                      │
└──────────────────────┴──────────────────────┘

Templates:
- node1: VMID 8000 (ubuntu-cloud-24.04)
- node2: VMID 8001 (ubuntu-cloud-24.04)
```

### Network Configuration

| Node            | IP Address      | Role    | Memory | CPU | Disk      |
|-----------------|-----------------|---------|--------|-----|-----------|
| k3s-master-01   | 10.10.11.1/23   | Master  | 4 GB   | 2   | 30 GB     |
| k3s-master-02   | 10.10.11.2/23   | Master  | 4 GB   | 2   | 30 GB     |
| k3s-master-03   | 10.10.11.3/23   | Master  | 4 GB   | 2   | 30 GB     |
| k3s-worker-01   | 10.10.11.11/23  | Worker  | 16 GB  | 4   | 30+300 GB |
| k3s-worker-02   | 10.10.11.12/23  | Worker  | 16 GB  | 4   | 30+300 GB |

**Gateway:** 10.10.10.1

---

## 🔧 Prerequisites

### 1. Proxmox Setup

- **Proxmox VE 9** cluster with 2 nodes
- **Non-shared storage**: local-lvm on each node
- **Cloud-init templates**:
  - VMID 8000 on node1 (Ubuntu 24.04)
  - VMID 8001 on node2 (Ubuntu 24.04)

### 2. Terraform User

Create the Terraform user and API token (run on any cluster node):

```bash
# See: homeops/1.proxmox/3.terraform_user_proxmox.md
pveum role add TerraformRole -privs "VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.Memory VM.Config.Network VM.Config.Options VM.Config.Cloudinit VM.Console VM.PowerMgmt Datastore.Allocate Datastore.AllocateSpace Datastore.Audit SDN.Use Pool.Allocate Sys.Audit Sys.Console VM.GuestAgent.Audit"

pveum user add terraform@pve --comment "Terraform Automation User"
pveum user token add terraform@pve tf --comment "Terraform API token"
pveum acl modify / -user terraform@pve -role TerraformRole
pveum acl modify /vms/8000 -user terraform@pve -role TerraformRole
pveum acl modify /vms/8001 -user terraform@pve -role TerraformRole
pveum acl modify /storage/local-lvm -user terraform@pve -role TerraformRole
```

### 3. Consul for State Management

**Already running on:** 10.10.10.15:8500

Verify Consul is accessible:
```bash
curl http://10.10.10.15:8500/v1/status/leader
```

### 4. Required Tools

```bash
# Install Terraform
wget https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
unzip terraform_1.9.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

---

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/mogallapuram/homeops.git
cd homeops/terraform/k3s-cluster

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

### 2. Add SSH Key

```bash
mkdir -p keys
cp ~/.ssh/id_rsa.pub keys/public-key.pub
```

### 3. Initialize Terraform

```bash
# Initialize with Consul backend
terraform init

# Verify Consul state backend
terraform show
```

**Expected output:**
```
Initializing the backend...

Successfully configured the backend "consul"!
```

### 4. Plan and Apply

```bash
# Review what will be created
terraform plan

# Create the K3s cluster VMs
terraform apply

# Or auto-approve
terraform apply -auto-approve
```

### 5. Verify Deployment

```bash
# Check VM distribution
terraform output node_distribution

# Get master node IPs
terraform output master_nodes

# Get worker node IPs
terraform output worker_nodes

# Full cluster summary
terraform output k3s_cluster_summary
```

---

## 📊 Terraform Outputs

After successful deployment:

```hcl
k3s_cluster_summary = {
  "k3s-master-01" = {
    "cores"        = 2
    "ip_address"   = "10.10.11.1/23"
    "memory_mb"    = 4096
    "proxmox_node" = "node1"
    "role"         = "master"
    "vm_id"        = 8201
  }
  # ... (additional nodes)
}

node_distribution = {
  "node1" = [
    "k3s-master-01",
    "k3s-master-03",
    "k3s-worker-02",
  ]
  "node2" = [
    "k3s-master-02",
    "k3s-worker-01",
  ]
}
```

---

## 🔄 State Management with Consul

### Why Consul?

- **Team Collaboration**: Multiple users can work on infrastructure
- **State Locking**: Prevents concurrent modifications
- **Centralized Storage**: State stored on dedicated server
- **Automatic Backups**: Consul handles replication

### State Operations

```bash
# View current state
terraform state list

# View specific resource
terraform state show proxmox_virtual_environment_vm.k3s_node[\"k3s-master-01\"]

# Force unlock (if lock is stuck)
terraform force-unlock <LOCK_ID>

# Pull state from Consul
terraform state pull
```

### Access Consul UI

```
http://10.10.10.15:8500/ui
```

Navigate to: **Key/Value → terraform/k3s-cluster/state**

---

## 🔐 Security Best Practices

### 1. Protect Sensitive Files

```bash
# Never commit these files
echo "terraform.tfvars" >> .gitignore
echo "*.tfstate" >> .gitignore
echo "*.tfstate.backup" >> .gitignore
echo ".terraform/" >> .gitignore
echo "keys/" >> .gitignore
```

### 2. Use Environment Variables (Alternative)

```bash
export TF_VAR_pm_api_token="terraform@pve!tf=YOUR-TOKEN"
export TF_VAR_consul_token="YOUR-CONSUL-TOKEN"
terraform apply
```

### 3. Rotate API Tokens

```bash
# Delete old token
pveum user token delete terraform@pve tf

# Create new token
pveum user token add terraform@pve tf

# Update terraform.tfvars
```

---

## 📈 Scaling the Cluster

### Add More Worker Nodes

Edit `main.tf` and add to `k3s_nodes`:

```hcl
k3s-worker-03 = { 
  vm_id           = 8213
  memory          = 16384
  cores           = 4
  role            = "worker"
  longhorn_disk_gb = 300
}
```

Add IP configuration in `terraform.tfvars`:

```hcl
node_ipv4 = {
  # ... existing nodes ...
  k3s-worker-03 = "10.10.11.13/23"
}
```

Apply changes:

```bash
terraform plan
terraform apply
```

**Round-robin distribution** will automatically place the new worker on the next available node!

### Add More Physical Nodes

1. Update `proxmox_nodes` in `main.tf`:
   ```hcl
   proxmox_nodes = ["node1", "node2", "node3"]
   ```

2. Add template mapping:
   ```hcl
   node_templates = {
     node1 = 8000
     node2 = 8001
     node3 = 8002  # Create template on node3
   }
   ```

3. Update permissions:
   ```bash
   pveum acl modify /vms/8002 -user terraform@pve -role TerraformRole
   ```

---

## 🐛 Troubleshooting

### Consul Connection Issues

```bash
# Test Consul connectivity
curl http://10.10.10.15:8500/v1/status/leader

# Check Consul logs
docker logs consul-consul-1

# Verify Consul is running
docker ps | grep consul
```

### State Lock Issues

```bash
# View lock info
terraform force-unlock -help

# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

### VM Creation Fails

```bash
# Check Terraform user permissions
pveum user permissions terraform@pve

# Verify template exists
qm list | grep 8000
qm list | grep 8001

# Check available storage
pvesm status
```

### SSH Connection Issues

```bash
# Verify SSH key was injected
ssh ram@10.10.11.1

# Check cloud-init logs on VM
ssh ram@10.10.11.1 'sudo cat /var/log/cloud-init.log'
```

---

## 📁 File Structure

```
homeops/
└── terraform/
    └── k3s-cluster/
        ├── main.tf                    # VM definitions & round-robin logic
        ├── provider.tf                # Proxmox provider & Consul backend
        ├── variables.tf               # Variable definitions
        ├── terraform.tfvars           # Actual values (DO NOT COMMIT)
        ├── terraform.tfvars.example   # Example configuration
        ├── .gitignore                 # Git ignore patterns
        ├── keys/
        │   └── public-key.pub        # SSH public key
        └── README.md                  # This file
```

---



---

## 🔗 Related Documentation

- [Proxmox Terraform User Setup](../1.proxmox/3.terraform_user_proxmox.md)
- [Cloud-Init Template Creation](../1.proxmox/2.cloud_init_template.md)
- [K3s Installation Guide](https://docs.k3s.io/installation)
- [Longhorn Documentation](https://longhorn.io/docs/)
- [Consul Documentation](https://www.consul.io/docs)

---

## 📝 Important Notes

### Non-Shared Storage

- VMs **cannot live-migrate** between nodes
- Use **offline migration** if needed (copies disk)
- Each node's local-lvm is **independent**
- Round-robin ensures **balanced distribution**

### State Locking

- Terraform **automatically locks** state during operations
- Only **one user** can modify infrastructure at a time
- Lock is **automatically released** after completion
- Use `force-unlock` only if lock is **truly stuck**

### Template Synchronization

Keep templates 8000 and 8001 **identical**:

```bash
# Export template from node1
qm exportovf 8000 /tmp/template

# Import to node2
scp -r /tmp/template node2:/tmp/
ssh node2 'qm importovf 8001 /tmp/template/*.ovf local-lvm'
```

---

## 👥 Team Collaboration

### For New Team Members

1. **Clone repository**:
   ```bash
   git clone https://github.com/mogallapuram/homeops.git
   cd homeops/terraform/k3s-cluster
   ```

2. **Initialize backend**:
   ```bash
   terraform init
   ```

3. **Review current state**:
   ```bash
   terraform plan
   ```

4. **Never bypass state locking**!

### Making Changes

```bash
# Always pull latest before making changes
git pull

# Initialize if needed
terraform init

# Review changes
terraform plan

# Apply with approval
terraform apply

# Commit changes to git (NOT terraform.tfvars!)
git add main.tf variables.tf
git commit -m "Add k3s-worker-03"
git push
```

---

## ⚠️ Critical Reminders

1. ✅ **Always use Consul backend** for team environments
2. ✅ **Never commit** `terraform.tfvars` to git
3. ✅ **Always run** `terraform plan` before `apply`
4. ✅ **Keep templates synchronized** across nodes
5. ✅ **Use descriptive** VM names and tags
6. ✅ **Document changes** in git commits

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-nodes`
3. Make changes
4. Test with `terraform plan`
5. Commit changes: `git commit -am 'Add new worker nodes'`
6. Push to branch: `git push origin feature/new-nodes`
7. Create Pull Request

---

## 📄 License

MIT License - See LICENSE file for details

---

**Author:** Ramakrishna Mogallapu  
**Project:** HomeOps — K3s Cluster on Proxmox  
**Infrastructure:** Proxmox VE 9 + Terraform + Consul  
**Last Updated:** December 29, 2025 
**Version:** 1.0.0

---

**Questions?** Open an issue on GitHub or contact the team.

**Enjoy your automated K3s homelab!** 🚀☁️
