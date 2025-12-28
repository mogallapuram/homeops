# 🔄 Template Configuration Update

## Summary of Changes

Changed from using **template IDs** (8000, 8001) to using **template name** for cleaner configuration.

---

## ✅ Benefits of Using Template Name

1. **Simpler Configuration**: No need to track different IDs per node
2. **Easier Maintenance**: Just keep the same template name on all nodes
3. **More Readable**: "ubuntu-cloud-24.04" is clearer than "8000"
4. **Automatic Selection**: Proxmox automatically uses the right template on each node

---

## 📝 What Changed

### 1. main.tf
**Before:**
```hcl
node_templates = {
  node1 = 8000
  node2 = 8001
}

clone {
  vm_id = each.value.template_id
  full  = true
}
```

**After:**
```hcl
# No node_templates mapping needed!

clone {
  vm_name = var.template_name  # Uses same name on both nodes
  full    = true
}
```

### 2. variables.tf
**Added:**
```hcl
variable "template_name" {
  description = "Cloud-init template name (same name on both nodes)"
  type        = string
  default     = "ubuntu-cloud-24.04"
}
```

### 3. terraform.tfvars
**Added:**
```hcl
template_name = "ubuntu-cloud-24.04"  # Your actual template name
```

---

## 🎯 How It Works

When you clone a VM:
1. Terraform sends request to specific node (via round-robin)
2. Proxmox looks for template with name "ubuntu-cloud-24.04" on that node
3. Clones from the local template

**Example:**
- VM goes to node1 → Clones from template "ubuntu-cloud-24.04" on node1
- VM goes to node2 → Clones from template "ubuntu-cloud-24.04" on node2

---

## 🔧 What You Need To Do

### 1. Ensure Templates Have Same Name

On **node1**:
```bash
qm set 8000 --name ubuntu-cloud-24.04
```

On **node2**:
```bash
qm set 8001 --name ubuntu-cloud-24.04
```

Or use the cluster-aware command from any node:
```bash
pvesh set /nodes/node1/qemu/8000/config --name ubuntu-cloud-24.04
pvesh set /nodes/node2/qemu/8001/config --name ubuntu-cloud-24.04
```

### 2. Update terraform.tfvars

Change this line to match your actual template name:
```hcl
template_name = "ubuntu-cloud-24.04"  # or whatever you named it
```

### 3. Deploy as Normal

```bash
terraform init
terraform plan
terraform apply
```

---

## ✨ Result

Cleaner, more maintainable configuration that's easier to understand and scale!

**Before**: "Why do I need template 8000 and 8001?"
**After**: "Clone from ubuntu-cloud-24.04" - much clearer!
