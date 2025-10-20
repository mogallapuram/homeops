# 🏡 HomeOps

**HomeOps** is my personal homelab project — an evolving setup designed to **build and manage a full-featured K3s cluster at home** using open-source technologies.  
This repository documents **every step**, including setup notes, known issues, architecture diagrams, and troubleshooting logs.

---

## 🚀 Project Overview

The goal of HomeOps is to create a **self-hosted, production-style environment** that mirrors real-world DevOps and cloud-native workflows — but entirely on-premises.

### ✨ Objectives
- Build and maintain a **K3s cluster** on home infrastructure.  
- Use **100% open-source tools** for deployment, monitoring, and automation.  
- Document **every step** — including errors, fixes, and lessons learned.  
- Keep it modular and reproducible using **Ansible**, **Helm**, and **Kubernetes manifests**.  

---

## 🧩 Tech Stack

| Category | Tools |
|-----------|-------|
| Operating System | **Ubuntu 25.10** |
| Kubernetes | [K3s](https://k3s.io/) |
| Automation | [Ansible](https://www.ansible.com/), [n8n](https://n8n.io/) |[terraform](https://developer.hashicorp.com/terraform)
| Orchestration | [Helm](https://helm.sh/) |
| Storage | NFS, Longhorn |
| Database | [Percona PostgreSQL for Kubernetes](https://www.percona.com/software/percona-distribution-for-postgresql) |
| Monitoring | Prometheus, Grafana |
| Networking | MetalLB, Kube-Vip, Cloudflare Tunnel, **Pi-hole** |
| Security | Vaultwarden, Keycloak |
| Apps | Immich, Nextcloud, Firefly III, Vaultwarden,etc .. |

---

## 🧰 Hardware (coming next)

This section will describe the physical and virtual infrastructure powering the HomeOps environment — including Proxmox hosts, CPU / RAM / Storage details, and node roles.

*(To be added next.)*
