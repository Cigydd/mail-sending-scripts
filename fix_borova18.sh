#!/bin/bash

# Function to prompt for input if parameter is empty
prompt_if_empty() {
    local var_name="$1"
    local prompt_text="$2"
    local default_value="$3"
    
    if [ -z "${!var_name}" ]; then
        if [ -n "$default_value" ]; then
            read -p "$prompt_text [$default_value]: " input
            input="${input:-$default_value}"
        else
            read -p "$prompt_text: " input
        fi
        eval "$var_name='$input'"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --remote-ssh-host)
            REMOTE_SSH_HOST="$2"
            shift 2
            ;;
        --local-hostname)
            LOCAL_HOSTNAME="$2"
            shift 2
            ;;
        --local-ip)
            LOCAL_IP="$2"
            shift 2
            ;;
        --network-range)
            NETWORK_RANGE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --output-dir <dir>         Output directory for log files"
            echo "  --remote-ssh-host <host>   Remote SSH hostname"
            echo "  --local-hostname <name>    Local hostname"
            echo "  --local-ip <ip>            Local IP address"
            echo "  --network-range <range>    Network range (e.g., 10.0.1.0/24)"
            echo "  --help                     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Prompt for required parameters if not provided
prompt_if_empty "OUTPUT_DIR" "Enter output directory" "$(pwd)"
prompt_if_empty "REMOTE_SSH_HOST" "Enter remote SSH hostname" "remote-server"
prompt_if_empty "LOCAL_HOSTNAME" "Enter local hostname" "$(hostname)"
prompt_if_empty "LOCAL_IP" "Enter local IP address"
prompt_if_empty "NETWORK_RANGE" "Enter network range" "10.0.1.0/24"

OUTPUT_FILE="$OUTPUT_DIR/${REMOTE_SSH_HOST}_fix_output.txt"

echo "=== Oprava Postfix na $REMOTE_SSH_HOST ===" > "$OUTPUT_FILE"

echo "1. Aktuální konfigurace:" >> "$OUTPUT_FILE"
ssh "$REMOTE_SSH_HOST" "postconf mynetworks" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "2. Přidání IP $LOCAL_HOSTNAME ($LOCAL_IP) do mynetworks..." >> "$OUTPUT_FILE"

ssh "$REMOTE_SSH_HOST" "sudo postconf -e 'mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $NETWORK_RANGE'" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "3. Nová konfigurace:" >> "$OUTPUT_FILE"
ssh "$REMOTE_SSH_HOST" "postconf mynetworks" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "4. Reload Postfix..." >> "$OUTPUT_FILE"
ssh "$REMOTE_SSH_HOST" "sudo systemctl reload postfix" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "5. Test konfigurace..." >> "$OUTPUT_FILE"
ssh "$REMOTE_SSH_HOST" "sudo postfix check" >> "$OUTPUT_FILE" 2>&1

echo "Hotovo: $(date)" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky v: $OUTPUT_FILE"