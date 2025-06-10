#!/bin/bash

# Skript pro nastavení Gmail relay přes vzdálený server
# Použití: ./setup_gmail_relay.sh [--output-dir OUTPUT_DIR] [--transport-map-path PATH]

# Výchozí hodnoty
OUTPUT_DIR="/tmp"
TRANSPORT_MAP_PATH="/etc/postfix/transport_remote-server"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Skript pro nastavení Gmail relay přes vzdálený server"
    echo ""
    echo "Použití: $0 [PARAMETRY]"
    echo ""
    echo "Parametry:"
    echo "  -o, --output-dir DIR     Adresář pro výstupní soubory (výchozí: /tmp)"
    echo "  -t, --transport-map-path PATH Cesta k transport mapě (výchozí: /etc/postfix/transport_remote-server)"
    echo "  -h, --help              Zobrazí tuto nápovědu"
    echo ""
    echo "Příklady:"
    echo "  $0"
    echo "  $0 --output-dir /var/log/mail-fixes --transport-map-path /etc/postfix/my_transport"
}

# Zpracování parametrů
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t|--transport-map-path)
            TRANSPORT_MAP_PATH="$2"
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

if [[ -z "$TRANSPORT_MAP_PATH" ]]; then
    echo "Chyba: Cesta k transport mapě nesmí být prázdná" >&2
    exit 1
fi

# Check if transport map directory exists
TRANSPORT_MAP_DIR=$(dirname "$TRANSPORT_MAP_PATH")
if [[ ! -d "$TRANSPORT_MAP_DIR" ]]; then
    echo "Chyba: Adresář '$TRANSPORT_MAP_DIR' pro transport mapu neexistuje" >&2
    exit 1
fi

OUTPUT_FILE="$OUTPUT_DIR/gmail_relay_output.txt"

echo "=== Nastavení Gmail relay přes remote-server ===" > "$OUTPUT_FILE"

echo "1. Přidání Gmail do transport mapy..." >> "$OUTPUT_FILE"
echo "gmail.com    smtp:[localhost]:2525" | sudo tee -a "$TRANSPORT_MAP_PATH" >> "$OUTPUT_FILE"
echo "*@gmail.com  smtp:[localhost]:2525" | sudo tee -a "$TRANSPORT_MAP_PATH" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "2. Aktualizace transport databáze..." >> "$OUTPUT_FILE"
sudo postmap "$TRANSPORT_MAP_PATH" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "3. Reload Postfix..." >> "$OUTPUT_FILE"
sudo systemctl reload postfix >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "4. Obsah transport mapy:" >> "$OUTPUT_FILE"
cat "$TRANSPORT_MAP_PATH" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "=== HOTOVO ===" >> "$OUTPUT_FILE"
echo "Gmail e-maily budou nyní odesílány přes remote-server!" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky v: $OUTPUT_FILE"