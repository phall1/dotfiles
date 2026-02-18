# Homelab "Jarvis" Architecture Guidelines

> Lessons from HashiCorp's Mitchell Hashimoto + tweaks for bare metal AI homelab

---

## Core Philosophy

Your homelab should be:
- **Declarative**: Entire system defined in code
- **Reproducible**: `git clone && apply` gets you back online
- **GitOps-driven**: Push to deploy, rollback via git
- **Bare-metal first**: Performance where you need it, containers where you don't

---

## 1. Infrastructure as Code (NixOS + Git)

```bash
# Your recovery procedure:
git clone https://github.com/YOUR_USERNAME/homelab.git ~/homelab
cd ~/homelab
make apply  # Or: sudo nixos-rebuild switch --flake .#jarvis
```

**Why NixOS?**
- Atomic upgrades/rollbacks
- Entire system config in one repo
- Reproducible across reinstalls
- No configuration drift

**Alternative if NixOS feels heavy**: 
- Ansible + Ubuntu LTS (more familiar, less pure)
- Proxmox + Terraform (VM-centric, easier GUI management)

---

## 2. Bare Metal First (Not VM-First)

Mitchell runs macOS + NixOS VM because he needs mac apps. **You don't.**

**Architecture:**
```
┌─────────────────────────────────────────────┐
│            Bare Metal NixOS                 │
│  ┌───────────────────────────────────────┐  │
│  │  Services (native systemd/Nix)        │  │
│  │  - Home Assistant                     │  │
│  │  - Ollama (AI inference)              │  │
│  │  - Tailscale                          │  │
│  └───────────────────────────────────────┘  │
│  ┌───────────────────────────────────────┐  │
│  │  Optional VMs/LXC (via libvirt/LXD)   │  │
│  │  - Experimental services              │  │
│  │  - Isolated workloads                 │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

**Rule**: Run performance-critical stuff natively. Use containers/VMs for:
- Isolation (untrusted services)
- Experimentation (try before native install)
- Multi-tenancy (separate environments)

---

## 3. Architecture Options (Pick Your Fighter)

### Option A: "Full NixOS" (Recommended for Learning)

**Stack:**
- **OS**: NixOS (bare metal)
- **Services**: NixOS modules (systemd services)
- **Containers**: Optional podman/docker-compose for specific apps
- **Secrets**: sops-nix or agenix
- **Network**: Tailscale for remote access

**Pros:**
- Maximum reproducibility
- Atomic upgrades
- Single source of truth
- No container overhead for AI/ML

**Cons:**
- Learning curve
- Smaller community than Docker
- Harder to find copy-paste solutions

**Best for**: You want to learn Nix properly, value reproducibility over convenience

---

### Option B: "NixOS + Docker Hybrid" (Pragmatic)

**Stack:**
- **OS**: NixOS (bare metal)
- **System Services**: NixOS native (Tailscale, monitoring agents)
- **User Services**: Docker Compose or Podman
- **AI/Home Automation**: Docker containers (Ollama, Home Assistant, Open WebUI)
- **Secrets**: Docker secrets or .env files + SOPS

**Pros:**
- Easier to find configs online (Docker Hub)
- Gradual migration path
- Can use Docker ecosystem
- Still reproducible via NixOS

**Cons:**
- Two mental models (Nix + Docker)
- Container overhead for AI workloads

**Best for**: You want NixOS benefits but don't want to package everything yourself

---

### Option C: "Traditional + GitOps" (Easiest Start)

**Stack:**
- **OS**: Ubuntu LTS or Fedora (bare metal)
- **Config**: Ansible playbooks in Git
- **Services**: Docker Compose for everything
- **GitOps**: Watchtower or Diun for auto-updates, or ArgoCD/Flux on k3s
- **Secrets**: Ansible Vault or SOPS

**Pros:**
- Familiar tooling
- Huge community/docs
- Easy to get help
- Can still do `git clone && ansible-playbook`

**Cons:**
- Not as reproducible as NixOS
- Configuration drift over time
- Manual intervention for OS-level changes

**Best for**: You want results fast, NixOS feels overwhelming

---

## 4. GitOps Workflow

**What is GitOps?** Your Git repo is the source of truth. Changes flow:

```
You edit configs → git push → automated deploy to your homelab
```

**For an individual's homelab, this means:**

### Simple Approach (No Kubernetes)

```bash
# On your development machine (laptop)
cd ~/homelab
git pull  # Get latest
vim home-assistant/configuration.yaml  # Edit
git add . && git commit -m "Update HA config"
git push

# On your homelab server (automated via cron or webhook)
cd /var/lib/homelab
git pull
make apply  # Or: docker-compose up -d, or: nixos-rebuild switch
```

**Tools:**
- **Basic**: Cron job every 5 min: `cd /var/lib/homelab && git pull && make apply`
- **Better**: Systemd timer + git hook
- **Fancy**: Gitea/Forgejo on homelab + webhook → trigger rebuild

**Result**: Yes, `git push` deploys to your own computer (the homelab server)

---

## 5. Bootstrap Process

Two-stage install (like Mitchell's approach):

### Stage 1: Base Install (Manual)

```bash
# 1. Create NixOS USB
# 2. Boot bare metal box
# 3. Partition, format, install minimal NixOS
# 4. Enable SSH, set root password

# Example (simplified):
sudo nixos-generate-config --root /mnt
# Copy your hardware config to repo
# Add SSH key for your user
nixos-install
reboot
```

### Stage 2: Configuration Deploy (Automated)

```bash
# On the new server:
git clone https://github.com/YOUR_USERNAME/homelab.git
cd homelab
make bootstrap

# This should:
# - Install all your services
# - Configure networking (Tailscale)
# - Restore secrets from backup
# - Start Home Assistant, Ollama, etc.
```

**Make targets to implement:**
```makefile
bootstrap:  # First-time setup
	./scripts/install-secrets.sh
	sudo nixos-rebuild switch --flake .#jarvis
	./scripts/restore-data.sh  # Restore HA backup, etc.

apply:  # Daily updates
	sudo nixos-rebuild switch --flake .#jarvis

test:  # Test changes without applying
	sudo nixos-rebuild test --flake .#jarvis
```

---

## 6. To Container or Not to Container?

**Short answer**: Not everything. Use native for performance, containers for isolation.

### What to Run Natively (NixOS modules)

| Service | Why Native |
|---------|-----------|
| **Ollama/AI inference** | GPU passthrough simpler, zero container overhead, direct CUDA access |
| **Home Assistant** | Can use host Bluetooth/Z-Wave/Zigbee dongles easily, less latency |
| **Tailscale** | Network-level, needs kernel modules |
| **Monitoring agents** | Host metrics, needs system access |
| **NFS/SMB** | File serving, performance matters |

### What to Containerize

| Service | Why Container |
|---------|--------------|
| **Open WebUI** | Web frontend, stateless, easy updates |
| **Plex/Jellyfin** | Sandboxed, can nuke & recreate easily |
| ***arr stack** (Sonarr, Radarr, etc.) | Lots of dependencies, better isolation |
| **Experimental services** | Easy to test & remove |
| **Databases** (optional) | Some prefer native for perf, but containers are fine |

### Performance Reality Check

**Container overhead is minimal EXCEPT:**
- GPU workloads (CUDA in containers adds complexity)
- High I/O (NFS/SMB might lose 5-10% throughput)
- Real-time stuff (audio, some home automation)

**Your setup**: Start native for AI/HA, containerize the rest. You can always migrate.

---

## 7. Network Architecture (Tailscale-Centric)

```
┌─────────────────────────────────────────┐
│         Your Apartment                  │
│  ┌───────────────────────────────────┐  │
│  │  Bare Metal NixOS (Jarvis)        │  │
│  │  - Tailscale subnet router        │  │
│  │  - Local DNS (Blocky or Pi-hole)  │  │
│  │  - Reverse proxy (Caddy/Traefik)  │  │
│  └───────────────────────────────────┘  │
│              │                          │
│         [Router/AP]                     │
└──────────────┼──────────────────────────┘
               │
        [Internet]
               │
    ┌──────────┴──────────┐
    │                     │
[Your Laptop]        [Friend's House]
(Tailscale)          (Shared Services)
[Phone]
```

**Key decisions:**
- **Tailscale**: VPN mesh for remote access, no port forwarding needed
- **Internal DNS**: `jarvis.local`, `ha.local`, `ai.local`
- **No VLANs initially**: Add when you have IoT/security concerns
- **Reverse proxy**: Caddy (simple) or Traefik (powerful) for HTTPS internally

---

## 8. Observability (Table for Later, But Plan For It)

**Don't implement now, but leave room:**

```nix
# In your NixOS config, leave placeholders:
# services.prometheus.enable = false;  # Enable later
# services.grafana.enable = false;     # Enable later
# services.loki.enable = false;        # Enable later
```

**Future stack (don't worry about it yet):**
- **Metrics**: Prometheus + Grafana
- **Logs**: Loki or Vector
- **Alerts**: Alertmanager → Discord/Slack/Telegram
- **Uptime**: Uptime Kuma (simple) or Healthchecks.io

---

## GPU Roadmap

**Phase 1 (Now)**: CPU inference with Ollama
- Small models (7B params) work fine on CPU
- Good for testing workflows

**Phase 2 (Later)**: Add GPU
- NVIDIA: Easiest, best CUDA support
- AMD: ROCm getting better, cheaper
- Intel Arc: Budget option, improving

**NixOS makes this easy:**
```nix
# services.ollama.enable = true;
# services.ollama.acceleration = "cuda";  # or "rocm"
```

---

## Claude Code + OpenCode Integration

Since you're using Claude Code subscription + OpenCode daily:

**Workflow:**
1. **Plan in Claude Code**: Architecture decisions, complex configs
2. **Implement in OpenCode**: Daily tweaks, quick fixes
3. **Both read the same repo**: Homelab configs are just code

**Tips:**
- Keep configs readable (commented, structured)
- Both tools can edit Nix files, Docker Compose, etc.
- Use `make test` before `make apply` when experimenting

---

## Recommended Starting Point

Given your constraints (decked out Linux box, no GPU yet, want results):

**Start with Option B: "NixOS + Docker Hybrid"**

```bash
# Week 1: Install NixOS bare metal
# - Minimal install
# - Tailscale
# - Docker/Podman

# Week 2: Docker Compose stack
# - Home Assistant
# - Ollama (CPU)
# - Open WebUI
# - Your choice: Plex, *arr stack, etc.

# Week 3: NixOS-ify system services
# - Move Tailscale to NixOS module
# - Add monitoring agents
# - Configure networking

# Week 4: GitOps
# - Set up auto-deploy
# - Document bootstrap process
# - Test: wipe VM, see if you can rebuild

# Later: Add GPU, migrate services to native NixOS
```

---

## File Structure to Create

```
~/homelab/
├── flake.nix              # NixOS system config
├── flake.lock             # Pinned dependencies
├── machines/
│   └── jarvis.nix         # Your bare metal hardware config
├── modules/
│   ├── home-assistant.nix # HA as NixOS module
│   ├── ollama.nix         # Ollama native service
│   └── tailscale.nix      # VPN setup
├── docker/
│   └── compose.yml        # Containerized services
├── secrets/
│   └── secrets.yaml       # SOPS-encrypted
├── Makefile               # Common tasks
└── scripts/
    ├── bootstrap.sh       # First-time setup
    └── backup.sh          # Data backup
```

---

## Next Steps

1. **Create the repo**: `mkdir ~/homelab && cd ~/homelab && git init`
2. **Install NixOS** on your bare metal box (keep it simple first)
3. **Copy your hardware config** into the repo
4. **Add one service** (Tailscale or Home Assistant)
5. **Test the bootstrap**: Can you rebuild from scratch?
6. **Iterate**: Add services one by one

---

## Questions to Answer Later

- [ ] Which reverse proxy? (Caddy vs Traefik vs Nginx)
- [ ] Secret management? (sops-nix vs agenix vs vault)
- [ ] Database: native PostgreSQL or container?
- [ ] Backups: BorgBackup, Restic, or something else?
- [ ] Do you need k3s/Kubernetes eventually?

**Don't overthink now. Start simple, evolve as needed.**
