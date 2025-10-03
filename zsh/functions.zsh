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
