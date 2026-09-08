#!/usr/bin/env bash
# Stub only native service boundaries; real installers run in the container rig.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-services.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/home/.config/dotfiles" "$scratch/home/.config/systemd/user"
export HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" CALLS="$scratch/calls"
export PATH="$scratch/bin:$PATH"
printf '%s\n' '{"services":true}' > "$XDG_CONFIG_HOME/dotfiles/profile.json"
cat > "$scratch/bin/blackbird" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == doctor ]]; then
  printf '%s\n' "$REPORT"
  exit "${DOCTOR_RC:-0}"
fi
echo "blackbird $*" >> "$CALLS"
STUB
cat > "$scratch/bin/phux" <<'STUB'
#!/usr/bin/env bash
echo "phux $*" >> "$CALLS"
if [[ "$*" == 'service status' ]]; then exit "${PHUX_STATUS_RC:-0}"; fi
STUB
printf '%s\n' '#!/bin/sh' 'echo Linux' > "$scratch/bin/uname"
printf '%s\n' '#!/bin/sh' 'exit 1' > "$scratch/bin/systemctl"
printf '%s\n' '#!/bin/sh' 'exit "${SOCKET_RC:-7}"' > "$scratch/bin/curl"
printf '%s\n' '#!/bin/sh' 'exit "${PROCESS_RC:-1}"' > "$scratch/bin/pgrep"
chmod +x "$scratch/bin/"*
export REPORT='{"checks":[{"name":"daemon.liveness","status":"pass"}]}' DOCTOR_RC=5
touch "$XDG_CONFIG_HOME/systemd/user/blackbird.service"
if bash "$root/scripts/bootstrap/services.sh" 2>/dev/null; then exit 1; fi
[[ ! -e "$CALLS" ]]
export DOCTOR_RC=0
bash "$root/scripts/bootstrap/services.sh"
if grep -q 'blackbird install' "$CALLS"; then exit 1; fi
rm "$XDG_CONFIG_HOME/systemd/user/blackbird.service" "$CALLS"
export REPORT='{"checks":[{"name":"database.schema","status":"fail"}]}' DOCTOR_RC=5
if bash "$root/scripts/bootstrap/services.sh" 2>/dev/null; then exit 1; fi
[[ ! -e "$CALLS" ]]
export REPORT='invalid-json'
if bash "$root/scripts/bootstrap/services.sh" 2>/dev/null; then exit 1; fi
[[ ! -e "$CALLS" ]]
export REPORT='{"checks":[{"name":"daemon.liveness","status":"fail"}]}'
for state in warn fail; do
  export REPORT="{\"checks\":[{\"name\":\"daemon.liveness\",\"status\":\"$state\"}]}" SOCKET_RC=0
  if bash "$root/scripts/bootstrap/services.sh" 2>/dev/null; then exit 1; fi
  [[ ! -e "$CALLS" ]]
done
export SOCKET_RC=7 PROCESS_RC=0
if bash "$root/scripts/bootstrap/services.sh" 2>/dev/null; then exit 1; fi
[[ ! -e "$CALLS" ]]
export PROCESS_RC=1
bash "$root/scripts/bootstrap/services.sh"
grep -qx 'blackbird install' "$CALLS"
export DOCTOR_RC=0 PHUX_STATUS_RC=1
touch "$XDG_CONFIG_HOME/systemd/user/blackbird.service" "$XDG_CONFIG_HOME/systemd/user/phux.service"
rm "$CALLS"
if bash "$root/scripts/bootstrap/services.sh" 2>/dev/null; then exit 1; fi
if grep -q 'install' "$CALLS"; then exit 1; fi
rm "$XDG_CONFIG_HOME/systemd/user/phux.service" "$CALLS"
bash "$root/scripts/bootstrap/services.sh"
grep -qx 'phux service install --adopt' "$CALLS"
rm "$CALLS"
printf '%s\n' '{"services":false}' > "$XDG_CONFIG_HOME/dotfiles/profile.json"
bash "$root/scripts/bootstrap/services.sh"
[[ ! -e "$CALLS" ]]
echo 'PASS: existing/failing services stay untouched; only absent installs provision; services-off skips native calls'
