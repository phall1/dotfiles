shelp() {
  local reset=$'\033[0m' bold=$'\033[1m' dim=$'\033[2m'
  local cyan=$'\033[36m' yellow=$'\033[33m' green=$'\033[32m' magenta=$'\033[35m'

  local -a skip=(_gstack_base _fc_dir _fc_just precmd chpwd)

  printf "\n"
  printf "  ${bold}${cyan}╭─────────────────────────────────────────────────────╮${reset}\n"
  printf "  ${bold}${cyan}│              shell aliases & functions               │${reset}\n"
  printf "  ${bold}${cyan}╰─────────────────────────────────────────────────────╯${reset}\n"

  printf "\n  ${bold}${yellow}ALIASES${reset}\n\n"
  alias | sort | while IFS='=' read -r name def; do
    def="${def#\'}"
    def="${def%\'}"
    [[ ${#def} -gt 60 ]] && def="${def:0:57}..."
    printf "  ${green}%-22s${reset} ${dim}%s${reset}\n" "$name" "$def"
  done

  printf "\n  ${bold}${yellow}FUNCTIONS${reset}\n\n"
  local -aU my_funcs=()
  local f
  for f in ~/.zsh/*.zsh; do
    [[ -f "$f" ]] || continue
    my_funcs+=( ${(f)"$(grep -oE '^[a-zA-Z_][a-zA-Z0-9_-]*\s*\(\)' "$f" | sed 's/[[:space:]]*()$//')"} )
    my_funcs+=( ${(f)"$(grep -oE '^function\s+[a-zA-Z_][a-zA-Z0-9_-]*' "$f" | sed 's/^function[[:space:]]*//')"} )
  done
  for f in "${(@o)my_funcs}"; do
    [[ "$f" == _* || "$f" == shelp ]] && continue
    printf "  ${magenta}%s${reset}\n" "$f"
  done

  printf "\n"
}

# Custom functions
function mkcd() {
    mkdir -p "$1" && cd "$1"
}
ec2-running() {
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],InstanceId]' \
        --output table
}

# Function to list stopped EC2 instances
ec2-stopped() {
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=stopped" \
        --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],InstanceId]' \
        --output table
}

# Function to list both running and stopped instances
ec2-list() {
    echo "=== RUNNING INSTANCES ==="
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],InstanceId,State.Name]' \
        --output table
    
    echo -e "\n=== STOPPED INSTANCES ==="
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=stopped" \
        --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],InstanceId,State.Name]' \
        --output table
}

# Alternative compact version that shows all states in one view
ec2-all() {
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running,stopped" \
        --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],InstanceId,State.Name]' \
        --output table
}

pgclidock() {
  local user="${1:-postgres}"
  local db="${2:-$user}"
  local host="${3:-localhost}"
  local port="${4:-5432}"

  if command -v pgcli >/dev/null 2>&1; then
    PGPASSWORD="${PGPASSWORD:-}" pgcli -h "$host" -p "$port" -U "$user" -d "$db"
  else
    echo "pgcli not found, install with: sudo apt install postgresql-client"
  fi
}

pgdock() {
  local user="${1:-postgres}"
  local db="${2:-$user}"
  local host="${3:-localhost}"
  local port="${4:-5432}"

  if command -v psql >/dev/null 2>&1; then
    PGPASSWORD="${PGPASSWORD:-}" psql -h "$host" -p "$port" -U "$user" -d "$db"
  else
    echo "psql not found, install with: sudo apt install postgresql-client"
  fi
}


eyebreak() {
  echo "Starting a 20-minute eye break timer..."
  (
    sleep 1200
    
    if [[ "$DOTFILES_OS" == "darwin" ]]; then
      # macOS notification
      osascript -e 'display notification "Look 20 feet away for 20 seconds." with title "Eye Break!"' 2>/dev/null
    elif [[ "$DOTFILES_OS" == "linux" ]]; then
      # Linux notification via notify-send or wall
      if command -v notify-send &>/dev/null; then
        notify-send "Eye Break!" "Look 20 feet away for 20 seconds." 2>/dev/null
      else
        echo -e "\n\033[1;33m=== EYE BREAK! ===\033[0m"
        echo "Look 20 feet away for 20 seconds."
        echo -e "==================\n"
      fi
    fi
  ) &
}



# shell wrapper that provides the ability to change the current working directory when exiting Yazi.
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Copy a file to the clipboard (as a file object on macOS, path on Linux)
function copyfile() {
  local filepath
  # Get absolute path (handles relative paths like ../file.txt)
  if [[ "$1" == /* ]]; then
    filepath="$1"
  else
    filepath="$PWD/$1"
  fi
  
  if [[ "$DOTFILES_OS" == "darwin" ]]; then
    # macOS: copy as file object
    osascript -e 'on run {f}' -e 'set the clipboard to POSIX file f' -e 'end run' "$filepath" 2>/dev/null
    echo "Copied $1 to clipboard (file)."
  elif [[ "$DOTFILES_OS" == "linux" ]]; then
    # Linux: copy path to clipboard
    if command -v xclip &>/dev/null; then
      echo -n "$filepath" | xclip -selection clipboard -in
      echo "Copied $1 path to clipboard."
    elif command -v wl-copy &>/dev/null; then
      echo -n "$filepath" | wl-copy
      echo "Copied $1 path to clipboard."
    else
      echo "Clipboard tool not found (install xclip or wl-clipboard)"
      return 1
    fi
  fi
}

# ============================================================================
# Remote Development Utilities
# ============================================================================

# SSH into a host with automatic tmux attachment
ssht() {
  local host="$1"
  shift
  ssh -t "$host" "tmux new-session -A -s main" "$@"
}

# Quick SSH tunnel for port forwarding
# Usage: tunnel <remote_host> <remote_port> [local_port]
tunnel() {
  local host="$1"
  local remote_port="$2"
  local local_port="${3:-$remote_port}"
  
  echo "Creating tunnel: localhost:$local_port → $host:$remote_port"
  ssh -N -L "${local_port}:localhost:${remote_port}" "$host"
}

# SSH tunnel with autossh (reconnects automatically)
# Usage: tunnel-persist <remote_host> <remote_port> [local_port]
tunnel-persist() {
  if ! command -v autossh &>/dev/null; then
    echo "autossh not installed. Falling back to regular ssh..."
    tunnel "$@"
    return
  fi
  
  local host="$1"
  local remote_port="$2"
  local local_port="${3:-$remote_port}"
  
  echo "Creating persistent tunnel: localhost:$local_port → $host:$remote_port"
  AUTOSSH_POLL=30 AUTOSSH_GATETIME=0 autossh -M 0 -N -L "${local_port}:localhost:${remote_port}" "$host"
}

# List all SSH tunnels currently active
tunnels() {
  echo "Active SSH tunnels:"
  ss -tulnp 2>/dev/null | grep -E "(Local Address|127.0.0.1)" || netstat -tulnp 2>/dev/null | grep "127.0.0.1"
  echo ""
  echo "SSH processes:"
  ps aux | grep -E "ssh.*-L" | grep -v grep
}

# Copy SSH public key to remote host (simplified ssh-copy-id)
ssh-copy() {
  local host="$1"
  local key="${2:-$HOME/.ssh/id_rsa.pub}"
  
  if [[ ! -f "$key" ]]; then
    echo "Key not found: $key"
    return 1
  fi
  
  echo "Copying $key to $host..."
  ssh "$host" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" < "$key"
  echo "Done!"
}

# Quick file transfer to remote
# Usage: to-remote <file> <host>:<path>
to-remote() {
  local file="$1"
  local dest="$2"
  rsync -avz --progress "$file" "$dest"
}

# Quick file transfer from remote
# Usage: from-remote <host>:<file> [local_path]
from-remote() {
  local src="$1"
  local dest="${2:-.}"
  rsync -avz --progress "$src" "$dest"
}

# Get public IP address
myip() {
  curl -s https://ipinfo.io/ip || curl -s https://api.ipify.org
}

# Get local IP addresses
localip() {
  if [[ "$DOTFILES_OS" == "darwin" ]]; then
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
  else
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
  fi
}

# Quick HTTP server in current directory
serve() {
  local port="${1:-8000}"
  if command -v python3 &>/dev/null; then
    echo "Serving on http://localhost:$port"
    python3 -m http.server "$port"
  elif command -v python &>/dev/null; then
    echo "Serving on http://localhost:$port"
    python -m SimpleHTTPServer "$port"
  else
    echo "Python not found"
    return 1
  fi
}

# Check if a port is open
port-check() {
  local host="${1:-localhost}"
  local port="$2"
  timeout 1 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null && echo "Port $port is open" || echo "Port $port is closed"
}

# Watch a command with a header
watch-cmd() {
  local title="$1"
  shift
  watch -n 1 -t "echo '=== $title ===' && $*"
}


header() {
  printf "\n\n\033[1;32m========================================\n"
  printf "   %s\n" "$1"
  printf "========================================\033[0m\n\n"
}

# Sync opencode dev branch with upstream
oc-sync() {
  local oc=~/workspace/opencode
  
  # Check for uncommitted changes
  if ! git -C "$oc" diff --quiet || ! git -C "$oc" diff --cached --quiet; then
    echo "You have uncommitted changes. Stash or commit first."
    return 1
  fi
  
  # Check if on dev branch
  local branch=$(git -C "$oc" branch --show-current)
  if [[ "$branch" != "dev" ]]; then
    echo "Not on dev branch (on '$branch'). Switch to dev first, or:"
    echo "  git -C $oc checkout dev"
    return 1
  fi
  
  git -C "$oc" fetch upstream && \
  git -C "$oc" rebase upstream/dev
}

# Build opencode from source (single platform)
oc-build() {
  echo "Building opencode..."
  bun run --cwd ~/workspace/opencode/packages/opencode build --single && \
  echo "Done. Run 'opencode --version' to verify."
}


# =============================================================================
# Git Stack Management
#
# Functions for working with stacked branches/PRs on GitHub.
# Share these by pointing people at your dotfiles repo.
#
# Base branch is auto-detected from origin/HEAD (whatever GitHub shows as
# default). Override per-repo with: git config gstack.base <branch>
# Or pass explicitly: gstack <branch>
# =============================================================================

_gstack_base() {
  # 1. Per-repo override via git config
  local configured
  configured=$(git config gstack.base 2>/dev/null)
  [[ -n "$configured" ]] && { echo "$configured"; return; }

  # 2. origin/HEAD (set by git clone, tracks GitHub default branch)
  local remote_head
  remote_head=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  [[ -n "$remote_head" ]] && { echo "${remote_head#refs/remotes/origin/}"; return; }

  # 3. Fallback: main > develop > master
  for branch in main develop master; do
    git rev-parse --verify "$branch" &>/dev/null && { echo "$branch"; return; }
  done

  echo "main"
}

gstack-help() {
  cat <<'EOF'
  gstack commands:

  gstack [base]              Show the branch stack (commits between layers)
  gstack-rebase [base]       Rebase the full stack bottom-up
  gstack-push [base]         Force-push (--force-with-lease) all stack branches
  gstack-status [base]       Show PR number, review state, and CI for each branch
  gstack-help                This message

  Base branch is auto-detected from origin/HEAD.
  Override per-repo:  git config gstack.base <branch>
  Override one-off:   gstack <branch>

  All commands support --help for details.
EOF
}

# Show the current branch stack (walk the chain of merge bases)
gstack() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'HELP'
gstack - Visualize the current branch stack

Usage: gstack [base]

Shows the chain of branches from your current branch down to the base
(auto-detected from origin/HEAD). Displays commit counts between each layer and
highlights the current branch.

Examples:
  gstack              # show stack based on main
  gstack develop      # show stack based on develop
HELP
    return 0
  fi

  local base="${1:-$(_gstack_base)}"
  local current
  current=$(git branch --show-current 2>/dev/null)
  if [[ -z "$current" ]]; then
    echo "Not on a branch (detached HEAD)." >&2
    return 1
  fi

  if ! git rev-parse --verify "$base" &>/dev/null; then
    echo "Base branch '$base' not found." >&2
    return 1
  fi

  local -a stack=()
  local branch="$current"

  # Collect all local branches that are ancestors of current AND descendants of base
  local dist name
  while read -r name; do
    [[ "$name" == "$base" ]] && continue
    # Branch must be: (1) descendant of base AND (2) ancestor of current
    if git merge-base --is-ancestor "$base" "$name" 2>/dev/null && \
       git merge-base --is-ancestor "$name" "$current" 2>/dev/null; then
      dist=$(git rev-list --count "$base".."$name" 2>/dev/null)
      [[ -n "$dist" && "$dist" -gt 0 ]] && stack+=("$dist:$name")
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

  # Sort by distance from base (ascending)
  local -a sorted=()
  local line
  while IFS= read -r line; do
    sorted+=("$line")
  done < <(printf '%s\n' "${stack[@]}" | sort -t: -k1 -n)

  # Print the stack
  echo ""
  printf "  \033[2m%s (base)\033[0m\n" "$base"
  local prev="$base" entry ahead marker color
  for entry in "${sorted[@]}"; do
    name="${entry#*:}"
    ahead=$(git rev-list --count "$prev".."$name" 2>/dev/null)
    marker="  "
    color="\033[0m"
    if [[ "$name" == "$current" ]]; then
      marker="→ "
      color="\033[1;33m"
    fi
    printf "  │ \033[2m+%s commit%s\033[0m\n" "$ahead" "$([[ $ahead -ne 1 ]] && echo s)"
    printf "  %b%s%s\033[0m\n" "$color" "$marker" "$name"
    prev="$name"
  done
  echo ""
}

# Rebase the entire stack above the current branch onto its updated base
gstack-rebase() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'HELP'
gstack-rebase - Rebase the stack above current branch

Usage: gstack-rebase [base]

Rebases every branch in the stack (from bottom to top) onto the
updated base. Useful after you amend a commit in a lower branch
and need the rest of the stack to catch up.

Stops on conflict and tells you which branch failed.

Examples:
  gstack-rebase            # rebase stack onto default branch
  gstack-rebase develop    # rebase stack onto develop
HELP
    return 0
  fi

  local base="${1:-$(_gstack_base)}"
  local current
  current=$(git branch --show-current 2>/dev/null)

  if ! git rev-parse --verify "$base" &>/dev/null; then
    echo "Base branch '$base' not found." >&2
    return 1
  fi

  # Collect branches in the stack, sorted by distance from base
  local -a stack=()
  local name dist line entry
  while read -r name; do
    [[ "$name" == "$base" ]] && continue
    # Branch must be: (1) descendant of base AND (2) related to current (ancestor OR descendant)
    if git merge-base --is-ancestor "$base" "$name" 2>/dev/null && \
       (git merge-base --is-ancestor "$name" "$current" 2>/dev/null || \
        git merge-base --is-ancestor "$current" "$name" 2>/dev/null); then
      dist=$(git rev-list --count "$base".."$name" 2>/dev/null)
      [[ -n "$dist" && "$dist" -gt 0 ]] && stack+=("$dist:$name")
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

  local -a sorted=()
  while IFS= read -r line; do
    sorted+=("$line")
  done < <(printf '%s\n' "${stack[@]}" | sort -t: -k1 -n)

  if [[ ${#sorted[@]} -eq 0 ]]; then
    echo "No branches found in the stack." >&2
    return 1
  fi

  echo "Rebasing stack onto $base..."
  local prev="$base"
  for entry in "${sorted[@]}"; do
    name="${entry#*:}"
    printf "  rebasing \033[1m%s\033[0m onto %s... " "$name" "$prev"
    if git rebase --onto "$prev" "$(git merge-base "$prev" "$name")" "$name" &>/dev/null; then
      printf "\033[32m✓\033[0m\n"
    else
      printf "\033[31m✗ CONFLICT\033[0m\n"
      echo ""
      echo "Conflict rebasing '$name'. Resolve with:"
      echo "  git rebase --continue   # after fixing conflicts"
      echo "  git rebase --abort      # to bail out"
      echo ""
      echo "Then re-run: gstack-rebase $base"
      return 1
    fi
    prev="$name"
  done

  # Return to original branch
  git checkout "$current" &>/dev/null
  echo ""
  printf "\033[32mStack rebased successfully.\033[0m\n"
  gstack "$base"
}

# Push the entire stack (all branches from base to current)
gstack-push() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'HELP'
gstack-push - Force-push all branches in the stack

Usage: gstack-push [base] [--dry-run]

Pushes every branch in the stack to origin. Uses --force-with-lease
for safety (won't overwrite someone else's changes).

Options:
  --dry-run    Show what would be pushed without pushing

Examples:
  gstack-push              # push stack (auto-detect base)
  gstack-push develop      # push stack (base=develop)
  gstack-push --dry-run    # preview what would be pushed
HELP
    return 0
  fi

  local base=""
  local dry_run=false
  for arg in "$@"; do
    case "$arg" in
      --dry-run) dry_run=true ;;
      -*) echo "Unknown flag: $arg" >&2; return 1 ;;
      *) base="$arg" ;;
    esac
  done
  [[ -z "$base" ]] && base="$(_gstack_base)"

  local current
  current=$(git branch --show-current 2>/dev/null)

  local -a stack=()
  local name dist line entry
  while read -r name; do
    [[ "$name" == "$base" ]] && continue
    # Branch must be: (1) descendant of base AND (2) ancestor of current (or is current)
    if git merge-base --is-ancestor "$base" "$name" 2>/dev/null && \
       (git merge-base --is-ancestor "$name" "$current" 2>/dev/null || \
        [[ "$name" == "$current" ]]); then
      dist=$(git rev-list --count "$base".."$name" 2>/dev/null)
      [[ -n "$dist" && "$dist" -gt 0 ]] && stack+=("$dist:$name")
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

  local -a sorted=()
  while IFS= read -r line; do
    sorted+=("$line")
  done < <(printf '%s\n' "${stack[@]}" | sort -t: -k1 -n)

  if [[ ${#sorted[@]} -eq 0 ]]; then
    echo "No branches found in the stack." >&2
    return 1
  fi

  for entry in "${sorted[@]}"; do
    name="${entry#*:}"
    if $dry_run; then
      printf "  would push \033[1m%s\033[0m\n" "$name"
    else
      printf "  pushing \033[1m%s\033[0m... " "$name"
      if git push --force-with-lease origin "$name" &>/dev/null; then
        printf "\033[32m✓\033[0m\n"
      else
        printf "\033[31m✗\033[0m\n"
        echo "Failed to push '$name'. Fix and retry."
        return 1
      fi
    fi
  done

  $dry_run && echo "(dry run — nothing pushed)"
}

# Show PR status for each branch in the stack
gstack-status() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'HELP'
gstack-status - Show PR status for each branch in the stack

Usage: gstack-status [base]

For each branch in the stack, shows:
  - Whether a PR exists and its number
  - PR review status (approved, changes requested, pending)
  - CI check status

Requires: gh CLI authenticated

Examples:
  gstack-status            # check stack against default branch
  gstack-status develop    # check stack against develop
HELP
    return 0
  fi

  local base="${1:-$(_gstack_base)}"
  local current
  current=$(git branch --show-current 2>/dev/null)

  if ! command -v gh &>/dev/null; then
    echo "gh CLI required. Install: brew install gh" >&2
    return 1
  fi

  local -a stack=()
  local name dist line entry
  while read -r name; do
    [[ "$name" == "$base" ]] && continue
    # Branch must be: (1) descendant of base AND (2) ancestor of current (or is current)
    if git merge-base --is-ancestor "$base" "$name" 2>/dev/null && \
       (git merge-base --is-ancestor "$name" "$current" 2>/dev/null || \
        [[ "$name" == "$current" ]]); then
      dist=$(git rev-list --count "$base".."$name" 2>/dev/null)
      [[ -n "$dist" && "$dist" -gt 0 ]] && stack+=("$dist:$name")
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

  local -a sorted=()
  while IFS= read -r line; do
    sorted+=("$line")
  done < <(printf '%s\n' "${stack[@]}" | sort -t: -k1 -n)

  if [[ ${#sorted[@]} -eq 0 ]]; then
    echo "No branches found in the stack." >&2
    return 1
  fi

  local marker pr_json pr_num pr_state review_status review_display
  local checks_pass checks_fail checks_pending ci_display state_display
  echo ""
  for entry in "${sorted[@]}"; do
    name="${entry#*:}"
    marker="  "
    [[ "$name" == "$current" ]] && marker="→ "

    pr_json=$(gh pr list --head "$name" --json number,state,reviewDecision,statusCheckRollup --limit 1 2>/dev/null)

    if [[ "$pr_json" == "[]" || -z "$pr_json" ]]; then
      printf "  %s\033[1m%-40s\033[0m \033[2mno PR\033[0m\n" "$marker" "$name"
    else
      pr_num=$(echo "$pr_json" | jq -r '.[0].number')
      pr_state=$(echo "$pr_json" | jq -r '.[0].state')
      review_status=$(echo "$pr_json" | jq -r '.[0].reviewDecision // "PENDING"')

      case "$review_status" in
        APPROVED)          review_display="\033[32m✓ approved\033[0m" ;;
        CHANGES_REQUESTED) review_display="\033[31m✗ changes requested\033[0m" ;;
        *)                 review_display="\033[33m○ review pending\033[0m" ;;
      esac

      checks_pass=$(echo "$pr_json" | jq '[.[0].statusCheckRollup[]? | select(.conclusion == "SUCCESS")] | length')
      checks_fail=$(echo "$pr_json" | jq '[.[0].statusCheckRollup[]? | select(.conclusion == "FAILURE")] | length')
      checks_pending=$(echo "$pr_json" | jq '[.[0].statusCheckRollup[]? | select(.conclusion == null or .conclusion == "")] | length')

      ci_display=""
      if [[ "$checks_fail" -gt 0 ]]; then
        ci_display=" \033[31mCI:${checks_pass}✓${checks_fail}✗\033[0m"
      elif [[ "$checks_pending" -gt 0 ]]; then
        ci_display=" \033[33mCI:running\033[0m"
      elif [[ "$checks_pass" -gt 0 ]]; then
        ci_display=" \033[32mCI:✓\033[0m"
      fi

      state_display=""
      [[ "$pr_state" == "MERGED" ]] && state_display=" \033[35m(merged)\033[0m"

      printf "  %s\033[1m%-40s\033[0m #%-5s %b%b%b\n" \
        "$marker" "$name" "$pr_num" "$review_display" "$ci_display" "$state_display"
    fi
  done
  echo ""
}
