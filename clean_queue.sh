#!/bin/bash

# Skript pro čištění mail fronty
# Použití: ./clean_queue.sh [--output-dir OUTPUT_DIR] [--remote-server HOSTNAME] [--user-email-pattern PATTERN]

# Výchozí hodnoty
OUTPUT_DIR="/tmp"
REMOTE_SERVER_HOSTNAME="remote-server.example.com"
USER_EMAIL_PATTERN="pavel@remote-server\.cz"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Skript pro čištění mail fronty"
    echo ""
    echo "Použití: $0 [PARAMETRY]"
    echo ""
    echo "Parametry:"
    echo "  -o, --output-dir DIR     Adresář pro výstupní soubory (výchozí: /tmp)"
    echo "  -s, --remote-server HOST Název vzdáleného serveru (výchozí: remote-server.example.com)"
    echo "  -p, --user-email-pattern PATTERN Vzor e-mailové adresy (regex) (výchozí: pavel@remote-server\\.cz)"
    echo "  -h, --help              Zobrazí tuto nápovědu"
    echo ""
    echo "Příklady:"
    echo "  $0"
    echo "  $0 --output-dir /var/log/mail-fixes --remote-server mail.example.com"
    echo "  $0 --user-email-pattern 'user@example\\.com'"
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
        -p|--user-email-pattern)
            USER_EMAIL_PATTERN="$2"
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

if [[ -z "$USER_EMAIL_PATTERN" ]]; then
    echo "Chyba: Vzor e-mailové adresy nesmí být prázdný" >&2
    exit 1
fi

OUTPUT_FILE="$OUTPUT_DIR/queue_output.txt"

echo "=== Čištění mail fronty ===" > "$OUTPUT_FILE"

echo "Fronta před čištěním:" >> "$OUTPUT_FILE"
mailq | head -5 >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "Mazání zpráv pro $REMOTE_SERVER_HOSTNAME..." >> "$OUTPUT_FILE"

# Smazání všech zpráv pro vzdálený server
sudo postqueue -p | grep -E "^[A-F0-9]+.*$USER_EMAIL_PATTERN" | cut -d' ' -f1 | while read queueid; do
    echo "Mažu: $queueid" >> "$OUTPUT_FILE"
    sudo postsuper -d $queueid
done

echo "" >> "$OUTPUT_FILE"
echo "Fronta po vyčištění:" >> "$OUTPUT_FILE"
mailq >> "$OUTPUT_FILE"

echo "Hotovo: $(date)" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky v: $OUTPUT_FILE"