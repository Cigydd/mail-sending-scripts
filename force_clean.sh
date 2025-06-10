#!/bin/bash

# Skript pro nucené vymazání všech zpráv ve frontě
# Použití: ./force_clean.sh [--output-dir OUTPUT_DIR]

# Výchozí hodnoty
OUTPUT_DIR="/tmp"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Skript pro nucené vymazání všech zpráv ve frontě"
    echo ""
    echo "Použití: $0 [PARAMETRY]"
    echo ""
    echo "Parametry:"
    echo "  -o, --output-dir DIR     Adresář pro výstupní soubory (výchozí: /tmp)"
    echo "  -h, --help              Zobrazí tuto nápovědu"
    echo ""
    echo "Příklady:"
    echo "  $0"
    echo "  $0 --output-dir /var/log/mail-fixes"
}

# Zpracování parametrů
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
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

OUTPUT_FILE="$OUTPUT_DIR/force_clean_output.txt"

echo "=== Nucené vymazání všech zpráv ve frontě ===" > "$OUTPUT_FILE"

echo "Stav před vymazáním:" >> "$OUTPUT_FILE"
mailq | tail -1 >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "Vymazání VŠECH zpráv ve frontě..." >> "$OUTPUT_FILE"

# Vymazání všech zpráv ve frontě
sudo postsuper -d ALL >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "Stav po vymazání:" >> "$OUTPUT_FILE"
mailq >> "$OUTPUT_FILE"

echo "Hotovo: $(date)" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky v: $OUTPUT_FILE"