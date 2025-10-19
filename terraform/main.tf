locals {
  nodes = {
    vkm1 = { vm_id = 8101, memory = 2048,  cores = 2, longhorn_disk_gb = 0 }
    vkm2 = { vm_id = 8102, memory = 2048,  cores = 2, longhorn_disk_gb = 0 }
    vkm3 = { vm_id = 8103, memory = 2048,  cores = 2, longhorn_disk_gb = 0 }
    vkn1 = { vm_id = 8111, memory = 16384, cores = 4, longhorn_disk_gb = 300 }
    vkn2 = { vm_id = 8112, memory = 16384, cores = 4, longhorn_disk_gb = 300 }
    ansible = { vm_id = 8120, memory = 4096, cores = 2, longhorn_disk_gb = 0 }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.nodes

  node_name = var.pm_node
  name      = each.key
  vm_id     = each.value.vm_id
  on_boot   = true
  started   = true

  clone {
    vm_id = var.template_vmid
    full  = true
  }

  cpu {
    sockets = 1
    cores   = each.value.cores
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    interface    = "scsi0"
    datastore_id = var.pm_datastore
    size         = var.root_disk_gb
    ssd          = true
    discard      = "on"
  }

  # Extra 300 GB disk for worker nodes
  dynamic "disk" {
    for_each = each.value.longhorn_disk_gb > 0 ? [1] : []
    content {
      interface    = "scsi1"
      datastore_id = var.pm_datastore
      size         = each.value.longhorn_disk_gb
      ssd          = true
      discard      = "on"
    }
  }

  scsi_hardware = "virtio-scsi-pci"

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = var.pm_datastore

    user_account {
      username = var.ci_user
      keys     = [file(var.ssh_public_key_path)] # /root/.ssh/id_rsa.pub
    }

    ip_config {
      ipv4 {
        address = var.node_ipv4[each.key]
        gateway = var.ipv4_gateway
      }
    }
  }

  agent {
    enabled = true
  }

  serial_device {}
  vga {
    type = "serial0"
  }

  tags = ["terraform", "homeops", "ubuntu25"]
}

output "vm_ids" {
  value = { for k, v in proxmox_virtual_environment_vm.vm : k => v.vm_id }
}

output "vm_ips" {
  value = var.node_ipv4
}
