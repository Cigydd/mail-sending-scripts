#!/bin/bash

# Skript pro konfiguraci Postfix pro SSH tunel
# Použití: ./configure_postfix_tunnel.sh [--output-dir OUTPUT_DIR] [--transport-map-name NAME] [--postfix-config-dir DIR]

# Výchozí hodnoty
OUTPUT_DIR="/tmp"
TRANSPORT_MAP_NAME="transport_remote-server"
POSTFIX_CONFIG_DIR="/etc/postfix"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Skript pro konfiguraci Postfix pro SSH tunel"
    echo ""
    echo "Použití: $0 [PARAMETRY]"
    echo ""
    echo "Parametry:"
    echo "  -o, --output-dir DIR     Adresář pro výstupní soubory (výchozí: /tmp)"
    echo "  -t, --transport-map-name NAME Název transport mapy (výchozí: transport_remote-server)"
    echo "  -p, --postfix-config-dir DIR Adresář s Postfix konfiguraci (výchozí: /etc/postfix)"
    echo "  -h, --help              Zobrazí tuto nápovědu"
    echo ""
    echo "Příklady:"
    echo "  $0"
    echo "  $0 --output-dir /var/log/mail-fixes --transport-map-name my_transport"
    echo "  $0 --postfix-config-dir /usr/local/etc/postfix"
}

# Zpracování parametrů
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t|--transport-map-name)
            TRANSPORT_MAP_NAME="$2"
            shift 2
            ;;
        -p|--postfix-config-dir)
            POSTFIX_CONFIG_DIR="$2"
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

if [[ ! -d "$POSTFIX_CONFIG_DIR" ]]; then
    echo "Chyba: Postfix konfigurační adresář '$POSTFIX_CONFIG_DIR' neexistuje" >&2
    exit 1
fi

if [[ -z "$TRANSPORT_MAP_NAME" ]]; then
    echo "Chyba: Název transport mapy nesmí být prázdný" >&2
    exit 1
fi

OUTPUT_FILE="$OUTPUT_DIR/postfix_tunnel_output.txt"

echo "=== Konfigurace Postfix pro SSH tunel ===" > "$OUTPUT_FILE"

echo "1. Vytvoření transport mapy..." >> "$OUTPUT_FILE"
sudo cp "/tmp/$TRANSPORT_MAP_NAME" "$POSTFIX_CONFIG_DIR/$TRANSPORT_MAP_NAME" 2>> "$OUTPUT_FILE"
echo "   Transport mapa zkopírována do $POSTFIX_CONFIG_DIR/" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "2. Vytvoření hash databáze..." >> "$OUTPUT_FILE"
sudo postmap "$POSTFIX_CONFIG_DIR/$TRANSPORT_MAP_NAME" 2>> "$OUTPUT_FILE"
echo "   Hash databáze vytvořena" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "3. Přidání transport_maps do main.cf..." >> "$OUTPUT_FILE"
MAIN_CF="$POSTFIX_CONFIG_DIR/main.cf"
TRANSPORT_ENTRY="hash:$POSTFIX_CONFIG_DIR/$TRANSPORT_MAP_NAME"
if grep -q "transport_maps" "$MAIN_CF"; then
    echo "   transport_maps již existuje, přidáváme k němu..." >> "$OUTPUT_FILE"
    # Escape forward slashes for sed
    ESCAPED_ENTRY=$(echo "$TRANSPORT_ENTRY" | sed 's/\//\\\//g')
    sudo sed -i "/^transport_maps/s/$/, $ESCAPED_ENTRY/" "$MAIN_CF" 2>> "$OUTPUT_FILE"
else
    echo "   Přidávám nový transport_maps..." >> "$OUTPUT_FILE"
    echo "transport_maps = $TRANSPORT_ENTRY" | sudo tee -a "$MAIN_CF" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "4. Kontrola konfigurace..." >> "$OUTPUT_FILE"
sudo postconf transport_maps >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "5. Reload Postfix..." >> "$OUTPUT_FILE"
sudo systemctl reload postfix 2>> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "6. Stav Postfix..." >> "$OUTPUT_FILE"
sudo systemctl status postfix --no-pager >> "$OUTPUT_FILE" 2>&1

echo "Hotovo: $(date)" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky v: $OUTPUT_FILE"