#!/bin/bash

# Skript pro manuální opravu vzdáleného serveru
# Použití: ./manual_borova18_fix.sh [--output-dir OUTPUT_DIR] [--remote-ssh-host HOST] [--network-range RANGE] [--remote-server HOSTNAME]

# Výchozí hodnoty
OUTPUT_DIR="/tmp"
REMOTE_SSH_HOST="remote-server"
NETWORK_RANGE="10.0.1.0/24"
REMOTE_SERVER_HOSTNAME="remote-server.example.com"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Skript pro manuální opravu vzdáleného serveru"
    echo ""
    echo "Použití: $0 [PARAMETRY]"
    echo ""
    echo "Parametry:"
    echo "  -o, --output-dir DIR     Adresář pro výstupní soubory (výchozí: /tmp)"
    echo "  -r, --remote-ssh-host HOST SSH host pro připojení (výchozí: remote-server)"
    echo "  -n, --network-range RANGE Síťový rozsah pro mynetworks (výchozí: 10.0.1.0/24)"
    echo "  -s, --remote-server HOSTNAME Název vzdáleného serveru (výchozí: remote-server.example.com)"
    echo "  -h, --help              Zobrazí tuto nápovědu"
    echo ""
    echo "Příklady:"
    echo "  $0"
    echo "  $0 --output-dir /var/log/mail-fixes --remote-ssh-host mail-server"
    echo "  $0 --network-range '192.168.1.0/24' --remote-server mail.example.com"
}

# Zpracování parametrů
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -r|--remote-ssh-host)
            REMOTE_SSH_HOST="$2"
            shift 2
            ;;
        -n|--network-range)
            NETWORK_RANGE="$2"
            shift 2
            ;;
        -s|--remote-server)
            REMOTE_SERVER_HOSTNAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Neznámý parametr: $1" >&2
            echo "Použijte --help pro nápovědu." >&2
            exit 1
            ;;
    esac
done

# Validace parametrů
if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Chyba: Adresář '$OUTPUT_DIR' neexistuje" >&2
    exit 1
fi

if [[ -z "$REMOTE_SSH_HOST" ]]; then
    echo "Chyba: SSH host nesmí být prázdný" >&2
    exit 1
fi

if [[ -z "$NETWORK_RANGE" ]]; then
    echo "Chyba: Síťový rozsah nesmí být prázdný" >&2
    exit 1
fi

if [[ -z "$REMOTE_SERVER_HOSTNAME" ]]; then
    echo "Chyba: Název vzdáleného serveru nesmí být prázdný" >&2
    exit 1
fi

OUTPUT_FILE="$OUTPUT_DIR/manual_fix_output.txt"

echo "=== Manuální oprava $REMOTE_SERVER_HOSTNAME ===" > "$OUTPUT_FILE"
echo "Spusť tyto příkazy ručně na $REMOTE_SERVER_HOSTNAME:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "1. SSH připojení:" >> "$OUTPUT_FILE"
echo "   ssh $REMOTE_SSH_HOST" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "2. Přidání IP do mynetworks:" >> "$OUTPUT_FILE"
echo "   sudo postconf -e 'mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $NETWORK_RANGE'" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "3. Reload Postfix:" >> "$OUTPUT_FILE"
echo "   sudo systemctl reload postfix" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "4. Test konfigurace:" >> "$OUTPUT_FILE"
echo "   sudo postfix check" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "5. Ověření změny:" >> "$OUTPUT_FILE"
echo "   postconf mynetworks" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Mezitím můžeme otestovat současný stav
echo "Aktuální test připojení:" >> "$OUTPUT_FILE"
telnet "$REMOTE_SERVER_HOSTNAME" 25 < /dev/null >> "$OUTPUT_FILE" 2>&1 &
sleep 3
kill %1 2>/dev/null

echo "Hotovo: $(date)" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky v: $OUTPUT_FILE"
cat "$OUTPUT_FILE"