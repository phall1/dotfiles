# Homelab (Jarvis) management functions
# Requires: Tailscale connected, SSH access to jarvis

JARVIS_HOST="${JARVIS_HOST:-jarvis}"

jarvis() {
  ssh -t "$JARVIS_HOST" "tmux new-session -A -s main" "$@"
}

jarvis-apply() {
  echo "Applying NixOS config on $JARVIS_HOST..."
  ssh "$JARVIS_HOST" "cd ~/homelab && git pull && sudo nixos-rebuild switch --flake .#jarvis"
}

jarvis-test() {
  echo "Testing NixOS config on $JARVIS_HOST (no switch)..."
  ssh "$JARVIS_HOST" "cd ~/homelab && git pull && sudo nixos-rebuild test --flake .#jarvis"
}

jarvis-logs() {
  local unit="${1:-}"
  if [ -n "$unit" ]; then
    ssh "$JARVIS_HOST" "journalctl -fu $unit"
  else
    ssh "$JARVIS_HOST" "journalctl -f"
  fi
}

jarvis-status() {
  ssh "$JARVIS_HOST" 'printf "\n"
    printf "  \033[1m%s\033[0m\n" "$(hostname)"
    printf "  uptime:  %s\n" "$(uptime -p 2>/dev/null || uptime)"
    printf "  kernel:  %s\n" "$(uname -r)"
    printf "  nixos:   %s\n" "$(nixos-version 2>/dev/null || echo "n/a")"
    printf "  cpu:     %s%%\n" "$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" 2>/dev/null || echo "n/a")"
    printf "  memory:  %s\n" "$(free -h | awk "/Mem:/ {printf \"%s / %s\", \$3, \$2}")"
    printf "  disk:    %s\n" "$(df -h / | awk "NR==2 {printf \"%s / %s (%s)\", \$3, \$2, \$5}")"
    printf "\n"
    printf "  \033[1mservices\033[0m\n"
    for svc in tailscaled ollama home-assistant docker; do
      if systemctl is-active --quiet "$svc" 2>/dev/null; then
        printf "  \033[32m●\033[0m %s\n" "$svc"
      else
        printf "  \033[31m○\033[0m %s\n" "$svc"
      fi
    done
    printf "\n"'
}

jarvis-sync-dotfiles() {
  echo "Syncing dotfiles to $JARVIS_HOST..."
  ssh "$JARVIS_HOST" "cd ~/dotfiles && git pull && ./stow-all.sh"
}

jarvis-docker() {
  ssh "$JARVIS_HOST" "docker $*"
}

jarvis-docker-ps() {
  ssh "$JARVIS_HOST" "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
}
