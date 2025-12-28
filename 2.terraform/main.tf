locals {
  # Proxmox nodes available in the cluster
  proxmox_nodes = ["node1", "node2"]
  
  # Template IDs per node (non-shared storage)
  # Keep templates with same name but need IDs for cloning
  node_templates = {
    node1 = 8000
    node2 = 8001
  }
  
  # K3s cluster configuration
  # 3 master nodes + 2 worker nodes
  k3s_nodes = {
    # Master nodes (control plane)
    k3s-master-01 = { 
      vm_id           = 8201
      memory          = 4096
      cores           = 2
      role            = "master"
      longhorn_disk_gb = 0
    }
    k3s-master-02 = { 
      vm_id           = 8202
      memory          = 4096
      cores           = 2
      role            = "master"
      longhorn_disk_gb = 0
    }
    k3s-master-03 = { 
      vm_id           = 8203
      memory          = 4096
      cores           = 2
      role            = "master"
      longhorn_disk_gb = 0
    }
    
    # Worker nodes (with Longhorn storage)
    k3s-worker-01 = { 
      vm_id           = 8211
      memory          = 16384
      cores           = 4
      role            = "worker"
      longhorn_disk_gb = 300
    }
    k3s-worker-02 = { 
      vm_id           = 8212
      memory          = 16384
      cores           = 4
      role            = "worker"
      longhorn_disk_gb = 300
    }
  }
  
  # Round-robin distribution: assign each VM to a node
  # This creates a map with node assignment for each VM
  vm_distribution = {
    for idx, vm_name in keys(local.k3s_nodes) : 
      vm_name => {
        proxmox_node = local.proxmox_nodes[idx % length(local.proxmox_nodes)]
        template_id  = local.node_templates[local.proxmox_nodes[idx % length(local.proxmox_nodes)]]
        config       = local.k3s_nodes[vm_name]
      }
  }
}

resource "proxmox_virtual_environment_vm" "k3s_node" {
  for_each = local.vm_distribution

  # Round-robin assigned node
  node_name = each.value.proxmox_node
  name      = each.key
  vm_id     = each.value.config.vm_id
  
  # VM lifecycle
  on_boot   = true
  started   = true
  
  # Tags for organization
  tags = [
    "terraform",
    "k3s",
    each.value.config.role,
    "homeops"
  ]

  # Clone from template (using ID - provider requires vm_id)
  clone {
    vm_id = each.value.template_id
    full  = true
  }

  # CPU configuration - cores only, no type specified
  cpu {
    sockets = 1
    cores   = each.value.config.cores
  }

  # Memory configuration
  memory {
    dedicated = each.value.config.memory
  }

  # Root disk
  disk {
    interface    = "scsi0"
    datastore_id = var.pm_datastore
    size         = var.root_disk_gb
    ssd          = true
    discard      = "on"
  }

  # Additional disk for Longhorn storage (workers only)
  dynamic "disk" {
    for_each = each.value.config.longhorn_disk_gb > 0 ? [1] : []
    content {
      interface    = "scsi1"
      datastore_id = var.pm_datastore
      size         = each.value.config.longhorn_disk_gb
      ssd          = true
      discard      = "on"
    }
  }

  scsi_hardware = "virtio-scsi-pci"

  # Network configuration
  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  # Cloud-init configuration
  initialization {
    datastore_id = var.pm_datastore

    user_account {
      username = var.ci_user
      keys     = [file(var.ssh_public_key_path)]
    }

    ip_config {
      ipv4 {
        address = var.node_ipv4[each.key]
        gateway = var.ipv4_gateway
      }
    }
  }

  # QEMU Guest Agent
  agent {
    enabled = true
  }

  # Serial console
  serial_device {}
  
  vga {
    type = "serial0"
  }
}

# Outputs for easy reference
output "k3s_cluster_summary" {
  description = "K3s cluster node distribution summary"
  value = {
    for vm_name, vm_config in local.vm_distribution : vm_name => {
      proxmox_node = vm_config.proxmox_node
      vm_id        = vm_config.config.vm_id
      ip_address   = var.node_ipv4[vm_name]
      role         = vm_config.config.role
      memory_mb    = vm_config.config.memory
      cores        = vm_config.config.cores
    }
  }
}

output "master_nodes" {
  description = "K3s master node IPs"
  value = {
    for vm_name, vm_config in local.vm_distribution : 
      vm_name => var.node_ipv4[vm_name]
      if vm_config.config.role == "master"
  }
}

output "worker_nodes" {
  description = "K3s worker node IPs"
  value = {
    for vm_name, vm_config in local.vm_distribution : 
      vm_name => var.node_ipv4[vm_name]
      if vm_config.config.role == "worker"
  }
}

output "node_distribution" {
  description = "How VMs are distributed across Proxmox nodes"
  value = {
    for node in local.proxmox_nodes : node => [
      for vm_name, vm_config in local.vm_distribution : vm_name
      if vm_config.proxmox_node == node
    ]
  }
}
