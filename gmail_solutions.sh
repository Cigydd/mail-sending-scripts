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
        --seznam-email)
            SEZNAM_EMAIL="$2"
            shift 2
            ;;
        --seznam-password)
            SEZNAM_PASSWORD="$2"
            shift 2
            ;;
        --gmail-email)
            GMAIL_EMAIL="$2"
            shift 2
            ;;
        --gmail-app-password)
            GMAIL_APP_PASSWORD="$2"
            shift 2
            ;;
        --tunnel-port)
            TUNNEL_PORT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --output-dir <dir>         Output directory for log files"
            echo "  --seznam-email <email>     Seznam.cz email address"
            echo "  --seznam-password <pass>   Seznam.cz password"
            echo "  --gmail-email <email>      Gmail email address"
            echo "  --gmail-app-password <pass> Gmail app password"
            echo "  --tunnel-port <port>       SSH tunnel port (default: 2525)"
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
prompt_if_empty "SEZNAM_EMAIL" "Enter Seznam.cz email address (optional, press Enter to skip)"
if [ -n "$SEZNAM_EMAIL" ]; then
    prompt_if_empty "SEZNAM_PASSWORD" "Enter Seznam.cz password"
fi
prompt_if_empty "GMAIL_EMAIL" "Enter Gmail email address (optional, press Enter to skip)"
if [ -n "$GMAIL_EMAIL" ]; then
    prompt_if_empty "GMAIL_APP_PASSWORD" "Enter Gmail app password"
fi
prompt_if_empty "TUNNEL_PORT" "Enter SSH tunnel port" "2525"

OUTPUT_FILE="$OUTPUT_DIR/gmail_solutions_output.txt"

echo "=== Řešení pro odesílání na Gmail ===" > "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "MOŽNOST 1: SMTP Relay přes seznam.cz (port 465)" >> "$OUTPUT_FILE"
echo "==========================================" >> "$OUTPUT_FILE"
echo "Pokud máš účet na seznam.cz, přidej do /etc/postfix/main.cf:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat >> "$OUTPUT_FILE" << 'EOF'
# SMTP relay pro Gmail
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_wrappermode = yes
relayhost = [smtp.seznam.cz]:465
EOF

echo "" >> "$OUTPUT_FILE"
echo "Pak vytvoř /etc/postfix/sasl_passwd:" >> "$OUTPUT_FILE"
if [ -n "$SEZNAM_EMAIL" ] && [ -n "$SEZNAM_PASSWORD" ]; then
    echo "[smtp.seznam.cz]:465    $SEZNAM_EMAIL:$SEZNAM_PASSWORD" >> "$OUTPUT_FILE"
else
    echo "[smtp.seznam.cz]:465    your_email@seznam.cz:your_password" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "MOŽNOST 2: SMTP Relay přes Gmail (port 587)" >> "$OUTPUT_FILE"
echo "==========================================" >> "$OUTPUT_FILE"
echo "Pokud máš Gmail účet s app password:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat >> "$OUTPUT_FILE" << 'EOF'
# SMTP relay přes Gmail
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_use_tls = yes
smtp_tls_security_level = encrypt
relayhost = [smtp.gmail.com]:587
EOF

echo "" >> "$OUTPUT_FILE"
echo "Pak vytvoř /etc/postfix/sasl_passwd:" >> "$OUTPUT_FILE"
if [ -n "$GMAIL_EMAIL" ] && [ -n "$GMAIL_APP_PASSWORD" ]; then
    echo "[smtp.gmail.com]:587    $GMAIL_EMAIL:$GMAIL_APP_PASSWORD" >> "$OUTPUT_FILE"
else
    echo "[smtp.gmail.com]:587    your_email@gmail.com:your_app_password" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "MOŽNOST 3: Použití remote-server jako relay" >> "$OUTPUT_FILE"
echo "=====================================" >> "$OUTPUT_FILE"
echo "Přesměrovat Gmail přes SSH tunel na remote-server:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Do /etc/postfix/transport přidat:" >> "$OUTPUT_FILE"
echo "gmail.com    smtp:[localhost]:$TUNNEL_PORT" >> "$OUTPUT_FILE"
echo "*@gmail.com  smtp:[localhost]:$TUNNEL_PORT" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "MOŽNOST 4: Sendgrid/Mailgun (Free tier)" >> "$OUTPUT_FILE"
echo "======================================" >> "$OUTPUT_FILE"
echo "Registruj se na sendgrid.com nebo mailgun.com" >> "$OUTPUT_FILE"
echo "Získáš API klíč a SMTP údaje zdarma pro malý objem" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "Příkazy pro implementaci:" >> "$OUTPUT_FILE"
echo "sudo postmap /etc/postfix/sasl_passwd" >> "$OUTPUT_FILE"
echo "sudo chmod 600 /etc/postfix/sasl_passwd*" >> "$OUTPUT_FILE"
echo "sudo systemctl reload postfix" >> "$OUTPUT_FILE"

cat "$OUTPUT_FILE"