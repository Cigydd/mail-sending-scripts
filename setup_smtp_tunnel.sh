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
prompt_if_empty "REMOTE_SSH_HOST" "Enter remote SSH hostname" "remote-server"
prompt_if_empty "REMOTE_SERVER_HOSTNAME" "Enter remote server full hostname" "remote-server.example.com"
prompt_if_empty "TUNNEL_PORT" "Enter local tunnel port" "2525"
prompt_if_empty "REMOTE_SMTP_PORT" "Enter remote SMTP port" "25"

OUTPUT_FILE="$OUTPUT_DIR/tunnel_setup_output.txt"

echo "=== Nastavení SSH tunelu pro SMTP ===" > "$OUTPUT_FILE"

# 1. Kontrola zda již neběží tunel
echo "1. Kontrola existujících tunelů..." >> "$OUTPUT_FILE"
ps aux | grep -E "ssh.*$TUNNEL_PORT:localhost:$REMOTE_SMTP_PORT.*$REMOTE_SSH_HOST" | grep -v grep >> "$OUTPUT_FILE" 2>&1

if ps aux | grep -E "ssh.*$TUNNEL_PORT:localhost:$REMOTE_SMTP_PORT.*$REMOTE_SSH_HOST" | grep -v grep > /dev/null; then
    echo "   Tunel již běží!" >> "$OUTPUT_FILE"
else
    echo "   Žádný tunel neběží, vytváříme nový..." >> "$OUTPUT_FILE"
    
    # 2. Vytvoření SSH tunelu na pozadí
    echo "" >> "$OUTPUT_FILE"
    echo "2. Vytváření SSH tunelu..." >> "$OUTPUT_FILE"
    echo "   Lokální port $TUNNEL_PORT -> $REMOTE_SSH_HOST:$REMOTE_SMTP_PORT" >> "$OUTPUT_FILE"
    
    ssh -f -N -L $TUNNEL_PORT:localhost:$REMOTE_SMTP_PORT "$REMOTE_SSH_HOST" 2>> "$OUTPUT_FILE"
    
    if [ $? -eq 0 ]; then
        echo "   ✓ Tunel vytvořen úspěšně" >> "$OUTPUT_FILE"
    else
        echo "   ✗ Chyba při vytváření tunelu" >> "$OUTPUT_FILE"
    fi
fi

# 3. Test tunelu
echo "" >> "$OUTPUT_FILE"
echo "3. Test tunelu..." >> "$OUTPUT_FILE"
timeout 3 telnet localhost "$TUNNEL_PORT" < /dev/null >> "$OUTPUT_FILE" 2>&1

# 4. Konfigurace pro Postfix
echo "" >> "$OUTPUT_FILE"
echo "4. Konfigurace pro Postfix..." >> "$OUTPUT_FILE"
echo "   Pro odesílání na $REMOTE_SERVER_HOSTNAME použij transport map:" >> "$OUTPUT_FILE"
echo "   $REMOTE_SERVER_HOSTNAME    smtp:[localhost]:$TUNNEL_PORT" >> "$OUTPUT_FILE"

# 5. Vytvoření transport mapy
echo "" >> "$OUTPUT_FILE"
echo "5. Vytvoření transport mapy..." >> "$OUTPUT_FILE"
echo "$REMOTE_SERVER_HOSTNAME    smtp:[localhost]:$TUNNEL_PORT" > "/tmp/transport_$REMOTE_SSH_HOST"
echo "   Transport mapa vytvořena v /tmp/transport_$REMOTE_SSH_HOST" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "=== HOTOVO ===" >> "$OUTPUT_FILE"
echo "Datum: $(date)" >> "$OUTPUT_FILE"

cat "$OUTPUT_FILE"