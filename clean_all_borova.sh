#!/bin/bash

# Skript pro vymazání všech zpráv pro vzdálený server
# Použití: ./clean_all_borova.sh [--output-dir OUTPUT_DIR] [--remote-server HOSTNAME] [--user-email EMAIL]

# Výchozí hodnoty
OUTPUT_DIR="/tmp"
REMOTE_SERVER_HOSTNAME="remote-server.example.com"
USER_EMAIL="user@remote-server.example.com"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Skript pro vymazání všech zpráv pro vzdálený server"
    echo ""
    echo "Použití: $0 [PARAMETRY]"
    echo ""
    echo "Parametry:"
    echo "  -o, --output-dir DIR     Adresář pro výstupní soubory (výchozí: /tmp)"
    echo "  -s, --remote-server HOST Název vzdáleného serveru (výchozí: remote-server.example.com)"
    echo "  -u, --user-email EMAIL   E-mailová adresa uživatele (výchozí: user@remote-server.example.com)"
    echo "  -h, --help              Zobrazí tuto nápovědu"
    echo ""
    echo "Příklady:"
    echo "  $0"
    echo "  $0 --output-dir /var/log/mail-fixes --remote-server mail.example.com"
    echo "  $0 --user-email pavel@example.com --remote-server mail.example.com"
}

# Zpracování parametrů
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -s|--remote-server)
            REMOTE_SERVER_HOSTNAME="$2"
            shift 2
            ;;
        -u|--user-email)
            USER_EMAIL="$2"
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

if [[ -z "$REMOTE_SERVER_HOSTNAME" ]]; then
    echo "Chyba: Název vzdáleného serveru nesmí být prázdný" >&2
    exit 1
fi

if [[ -z "$USER_EMAIL" ]]; then
    echo "Chyba: E-mailová adresa nesmí být prázdná" >&2
    exit 1
fi

OUTPUT_FILE="$OUTPUT_DIR/clean_all_output.txt"

echo "=== Vymazání všech zpráv pro $REMOTE_SERVER_HOSTNAME ===" > "$OUTPUT_FILE"

echo "Počet zpráv před vymazáním:" >> "$OUTPUT_FILE"
mailq | grep -c "$USER_EMAIL" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "Mazání všech zpráv pro $REMOTE_SERVER_HOSTNAME..." >> "$OUTPUT_FILE"

# Vymazání všech zpráv obsahujících vzdálený server
# Escape dots in hostname for regex
ESCAPED_HOSTNAME=$(echo "$REMOTE_SERVER_HOSTNAME" | sed 's/\./\\./g')
sudo postqueue -p | awk "/$ESCAPED_HOSTNAME/ {print \$1}" | grep -E '^[A-F0-9]+$' | while read queueid; do
    echo "Mažu: $queueid" >> "$OUTPUT_FILE"
    sudo postsuper -d $queueid 2>> "$OUTPUT_FILE"
done

echo "" >> "$OUTPUT_FILE"
echo "Kontrola zbývajících zpráv:" >> "$OUTPUT_FILE"
mailq | grep -A1 -B1 "$REMOTE_SERVER_HOSTNAME" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "Celkový stav fronty:" >> "$OUTPUT_FILE"
mailq | tail -1 >> "$OUTPUT_FILE"

echo "Hotovo: $(date)" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky v: $OUTPUT_FILE"