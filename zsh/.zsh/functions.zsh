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
  # This runs the sleep command in the background (&)
  # so you get your terminal prompt back immediately.
  (
    sleep 1200 # 1200 seconds = 20 minutes
    
    # 'osascript' is the command to run AppleScript on macOS
    osascript -e 'display notification "Look 20 feet away for 20 seconds." with title "Eye Break!"'
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
