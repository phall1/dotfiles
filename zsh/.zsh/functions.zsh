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

