# Homelab Bootstrap Checklist

Everything to do **before** you touch the bare metal box.

---

## 1. Tailscale Prep

- [ ] **Auth key**: Generate a reusable, ephemeral auth key at https://login.tailscale.com/admin/settings/keys
  - Check "Reusable" and "Ephemeral" for unattended bootstrap
  - Set expiry to 90 days (or no expiry for homelab)
  - Save it in your password manager
- [ ] **ACL tags**: Add `tag:homelab` to your Tailscale ACL policy:
  ```json
  "tagOwners": {
    "tag:homelab": ["autogroup:admin"]
  }
  ```
- [ ] **ACL rules**: Allow your devices to reach homelab services:
  ```json
  { "action": "accept", "src": ["autogroup:member"], "dst": ["tag:homelab:*"] }
  ```
- [ ] **MagicDNS**: Enable at https://login.tailscale.com/admin/dns
  - Gives you `jarvis.<tailnet>.ts.net` automatically
- [ ] **Tailscale SSH**: Enable in ACLs for key-free SSH:
  ```json
  "ssh": [
    { "action": "accept", "src": ["autogroup:member"], "dst": ["tag:homelab"], "users": ["autogroup:nonroot"] }
  ]
  ```

## 2. Secret Management (sops-nix + age)

### Generate your age key (do this on your Mac NOW)

```bash
# Install age
brew install age

# Generate key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Note the public key (starts with "age1...")
age-keygen -y ~/.config/sops/age/keys.txt
```

### Set up .sops.yaml in your homelab repo

```yaml
# ~/homelab/.sops.yaml
keys:
  - &admin age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # your public key

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
        - *admin
```

### Encrypt a secret

```bash
# Create a secrets file
sops secrets/homelab.yaml
# This opens your editor — add key-value pairs, they get encrypted on save

# Or encrypt an existing file
sops -e -i secrets/homelab.yaml
```

### Transfer key to homelab (during bootstrap)

```bash
# Copy your age key to the server
scp ~/.config/sops/age/keys.txt jarvis:~/.config/sops/age/keys.txt

# Or use Tailscale file sending
tailscale file cp ~/.config/sops/age/keys.txt jarvis:
```

## 3. NixOS USB Installer

- [ ] Download the minimal NixOS ISO: https://nixos.org/download#nixos-iso
- [ ] Flash to USB: `dd if=nixos-minimal.iso of=/dev/diskN bs=4M status=progress`
  - Or use Balena Etcher / Ventoy
- [ ] Have a keyboard + monitor ready for initial install

## 4. Create the Homelab Repo

```bash
mkdir -p ~/homelab
cd ~/homelab
git init
```

See `docs/homelab-jarvis-guidelines.md` for the full flake structure.

### Minimal flake.nix to start with

```nix
{
  description = "Jarvis homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, sops-nix, ... }: {
    nixosConfigurations.jarvis = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./machines/jarvis
        sops-nix.nixosModules.sops
        {
          # Tailscale
          services.tailscale.enable = true;

          # Basic system
          networking.hostName = "jarvis";
          time.timeZone = "America/New_York";

          # Your user
          users.users.phall = {
            isNormalUser = true;
            extraGroups = [ "wheel" "docker" ];
            openssh.authorizedKeys.keys = [
              # Paste your SSH public key here
              # Or rely on Tailscale SSH
            ];
          };

          # Essential services
          services.openssh.enable = true;
          virtualisation.docker.enable = true;

          system.stateVersion = "24.11";
        }
      ];
    };
  };
}
```

## 5. Test in a VM First

### Option A: UTM (macOS, free)

```bash
# Download NixOS minimal ISO
# Create new VM in UTM:
#   - Type: Linux
#   - Architecture: x86_64 (emulated) or aarch64 (virtualized on Apple Silicon)
#   - RAM: 4GB+
#   - Disk: 20GB+
# Boot the ISO, install NixOS, then:
git clone https://github.com/YOUR_USERNAME/homelab.git ~/homelab
cd ~/homelab
sudo nixos-rebuild switch --flake .#jarvis
```

### Option B: OrbStack (macOS, fast)

```bash
# OrbStack supports NixOS machines directly
orb create nixos jarvis
# Then SSH in and test your flake
```

### Option C: nixos-rebuild in a container (quick smoke test)

```bash
# Build the config without applying (checks for syntax errors)
nix build .#nixosConfigurations.jarvis.config.system.build.toplevel
```

## 6. Dotfiles Portability Verification

Before deploying to NixOS, verify your dotfiles work on Linux:

```bash
# In your NixOS VM:
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

# Check:
# - [ ] zshrc loads without errors
# - [ ] Starship prompt renders
# - [ ] tmux starts with correct theme
# - [ ] Neovim opens, plugins install
# - [ ] Git config is correct (personal email, not work)
# - [ ] Tailscale is running: tailscale status
```

## 7. Hardware Prep

- [ ] Know your target machine's specs (CPU, RAM, disk, GPU if any)
- [ ] Have ethernet cable ready (WiFi during NixOS install is painful)
- [ ] BIOS settings: enable virtualization (VT-x/VT-d), set boot order to USB first
- [ ] If NVIDIA GPU: note the model — you'll need `hardware.nvidia` config

## 8. Day-One Script

After NixOS minimal install + SSH access:

```bash
# On the fresh NixOS box:
git clone https://github.com/YOUR_USERNAME/homelab.git ~/homelab
cd ~/homelab
sudo nixos-rebuild switch --flake .#jarvis

# Dotfiles
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

# Tailscale
sudo tailscale up --auth-key=tskey-auth-XXXXX --advertise-tags=tag:homelab

# Verify
tailscale status
jarvis-status  # from your Mac, if Tailscale is connected
```

---

**You are now ready to nuke and pave anytime with just `git clone && make apply`.**
