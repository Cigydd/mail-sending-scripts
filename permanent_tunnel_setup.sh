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
        --ssh-user)
            SSH_USER="$2"
            shift 2
            ;;
        --remote-ssh-host)
            REMOTE_SSH_HOST="$2"
            shift 2
            ;;
        --remote-server-hostname)
            REMOTE_SERVER_HOSTNAME="$2"
            shift 2
            ;;
        --tunnel-port)
            TUNNEL_PORT="$2"
            shift 2
            ;;
        --remote-smtp-port)
            REMOTE_SMTP_PORT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --output-dir <dir>          Output directory for log files"
            echo "  --ssh-user <user>           SSH username"
            echo "  --remote-ssh-host <host>    Remote SSH hostname"
            echo "  --remote-server-hostname <host> Remote server full hostname"
            echo "  --tunnel-port <port>        Local tunnel port (default: 2525)"
            echo "  --remote-smtp-port <port>   Remote SMTP port (default: 25)"
            echo "  --help                      Show this help message"
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
prompt_if_empty "SSH_USER" "Enter SSH username" "$(whoami)"
prompt_if_empty "REMOTE_SSH_HOST" "Enter remote SSH hostname" "remote-server"
prompt_if_empty "REMOTE_SERVER_HOSTNAME" "Enter remote server full hostname" "remote-server.example.com"
prompt_if_empty "TUNNEL_PORT" "Enter local tunnel port" "2525"
prompt_if_empty "REMOTE_SMTP_PORT" "Enter remote SMTP port" "25"

OUTPUT_FILE="$OUTPUT_DIR/permanent_tunnel_output.txt"

echo "=== Nastavení trvalého SSH tunelu pro $REMOTE_SSH_HOST ===" > "$OUTPUT_FILE"

echo "1. Vytvoření systemd služby pro SSH tunel..." >> "$OUTPUT_FILE"

cat > "/tmp/smtp-tunnel-$REMOTE_SSH_HOST.service" << EOF
[Unit]
Description=SSH Tunnel for SMTP to $REMOTE_SSH_HOST
After=network.target

[Service]
Type=simple
User=$SSH_USER
ExecStart=/usr/bin/ssh -N -L $TUNNEL_PORT:localhost:$REMOTE_SMTP_PORT $REMOTE_SSH_HOST
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

echo "   Služba vytvořena v /tmp/smtp-tunnel-$REMOTE_SSH_HOST.service" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "2. Instalace služby..." >> "$OUTPUT_FILE"
echo "   Spusť jako root:" >> "$OUTPUT_FILE"
echo "   sudo cp /tmp/smtp-tunnel-$REMOTE_SSH_HOST.service /etc/systemd/system/" >> "$OUTPUT_FILE"
echo "   sudo systemctl daemon-reload" >> "$OUTPUT_FILE"
echo "   sudo systemctl enable smtp-tunnel-$REMOTE_SSH_HOST" >> "$OUTPUT_FILE"
echo "   sudo systemctl start smtp-tunnel-$REMOTE_SSH_HOST" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "3. Vyčištění fronty starých zpráv pro $REMOTE_SERVER_HOSTNAME..." >> "$OUTPUT_FILE"
sudo postqueue -p | grep -B1 "$REMOTE_SERVER_HOSTNAME" | grep -E "^[A-F0-9]+" | cut -d' ' -f1 | while read qid; do
    echo "   Mažu: $qid" >> "$OUTPUT_FILE"
    sudo postsuper -d $qid 2>> "$OUTPUT_FILE"
done

echo "" >> "$OUTPUT_FILE"
echo "4. Stav fronty po vyčištění:" >> "$OUTPUT_FILE"
mailq | tail -3 >> "$OUTPUT_FILE"

echo "Hotovo: $(date)" >> "$OUTPUT_FILE"
cat "$OUTPUT_FILE"